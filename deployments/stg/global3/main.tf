/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "alloydb_primary" {
  source  = "GoogleCloudPlatform/alloy-db/google"
  version = "~> 3.0"

  cluster_id           = var.cluster_id
  cluster_location     = var.region_primary
  project_id           = var.project_id
  cluster_display_name = var.cluster_name
  cluster_initial_user = {
    user     = var.cluster_initial_username,
    password = google_secret_manager_secret_version.alloydb_secret_version.secret_data
  }
  psc_enabled                   = var.psc_enabled
  psc_allowed_consumer_projects = [var.psc_attachment_project_number]

  cluster_encryption_key_name = google_kms_crypto_key.key_region_primary.id

  automated_backup_policy = {
    location                       = var.region_primary
    backup_window                  = var.backup_window
    enabled                        = var.automated_backup_enabled
    weekly_schedule                = var.weekly_schedule
    quantity_based_retention_count = var.quantity_based_retention_count
    time_based_retention_count     = var.time_based_retention_count
    labels                         = var.backup_labels
    backup_encryption_key_name     = google_kms_crypto_key.key_region_primary.id
  }

  continuous_backup_recovery_window_days = var.continuous_backup_recovery_window_days
  continuous_backup_encryption_key_name  = google_kms_crypto_key.key_region_primary.id

  primary_instance = {
    instance_id           = var.primary_instance.instance_id
    display_name          = var.primary_instance.display_name
    availability_type     = var.primary_instance.availability_type
    database_flags        = local.merged_database_flags
    labels                = var.primary_instance.labels
    annotations           = var.primary_instance.annotations
    gce_zone              = var.primary_instance.gce_zone
    require_connectors    = var.primary_instance.require_connectors
    ssl_mode              = var.primary_instance.ssl_mode == null ? "ENCRYPTED_ONLY" : var.primary_instance.ssl_mode
    query_insights_config = var.primary_instance.query_insights_config
    enable_public_ip      = var.primary_instance.enable_public_ip
    cidr_range            = var.primary_instance.cidr_range
  machine_cpu_count = var.primary_instance.machine_cpu_count }

  #   read_pool_instance = [
  #     for _, read_instance in var.read_pool_instances : {
  #       instance_id           = read_instance.instance_id
  #       display_name          = read_instance.display_name
  #       node_count            = read_instance.node_count
  #       machine_type          = "db-custom-${read_instance.machine_cpu_count}-3840" # Changed interpolation
  #       availability_type     = read_instance.availability_type
  #       database_flags        = read_instance.database_flags
  #       gce_zone              = read_instance.gce_zone
  #       require_connectors    = var.primary_instance.require_connectors
  #       ssl_mode              = read_instance.ssl_mode == null ? "ENCRYPTED_ONLY" : read_instance.ssl_mode
  #       query_insights_config = read_instance.query_insights_config
  #       enable_public_ip      = read_instance.enable_public_ip
  #       cidr_range            = read_instance.cidr_range
  #       machine_cpu_count     = read_instance.machine_cpu_count
  #     }
  #   ]

  depends_on = [
    google_kms_crypto_key_iam_member.alloydb_sa_iam,
    google_kms_crypto_key.key_region_primary,
  ]
}

# Local Variable Declaration
locals {
  default_database_flags = {
    log_error_verbosity           = "default"
    log_connections               = "on"
    log_disconnections            = "on"
    log_statement                 = "all"
    log_min_messages              = "warning"
    log_min_error_statement       = "error"
    log_min_duration_statement    = "-1"
    "password.enforce_complexity" = "on" //Important for security
    "alloydb.enable_pgaudit"      = "on"
    "alloydb.iam_authentication"  = "on"
  }

  merged_database_flags = merge(local.default_database_flags, var.primary_instance.database_flags)
}

# Create KMS Resources

resource "google_project_service_identity" "alloydb_sa" {
  provider = google-beta

  project = var.project_id
  service = "alloydb.googleapis.com"
}

resource "random_string" "key_suffix" {
  length  = 3
  special = false
  upper   = false
}

resource "google_kms_key_ring" "keyring_region_primary" {
  project  = var.project_id
  name     = "keyring-${var.region_primary}-${random_string.key_suffix.result}"
  location = var.region_primary
}

resource "google_kms_crypto_key" "key_region_primary" {
  name     = "key-${var.region_primary}-${random_string.key_suffix.result}"
  key_ring = google_kms_key_ring.keyring_region_primary.id
}


resource "google_kms_crypto_key_iam_member" "alloydb_sa_iam" {
  crypto_key_id = google_kms_crypto_key.key_region_primary.id
  role          = join(",", var.alloydb_sa_iam_role)
  member        = "serviceAccount:${google_project_service_identity.alloydb_sa.email}"
}


# Generate random password and store it in secret manager
resource "random_password" "initial_user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "alloydb_secret" {
  secret_id = "alloydb-initial-user-password"
  project   = var.project_id
  replication {
    auto {} # Replicate the secret automatically to all regions
  }
}

resource "google_secret_manager_secret_version" "alloydb_secret_version" {
  secret      = google_secret_manager_secret.alloydb_secret.id
  secret_data = random_password.initial_user_password.result
}

### Working example of creating Database and Run query by using local_exec provisioner
## Pre-requisite: 1. Must enable Public IP for the Primary Instance
##                2. Must whitelist the runner IP in the Authorized network

# Create Table in the default postgres db
# resource "null_resource" "run_query" {
#   depends_on = [module.alloydb_primary]
#   provisioner "local-exec" {
#     command     = <<EOF
#       PGPASSWORD="postgres" 
#       psql -h ${module.alloydb_primary.primary_instance.public_ip_address} \
#            -U "postgres"  \
#            -p 5432  \
#            -d postgres \
#            -c "CREATE TABLE my_table (id SERIAL PRIMARY KEY, name VARCHAR(255));"
#     EOF
#     interpreter = ["bash", "-c"]
#     }
# }

# Create a new db
# resource "null_resource" "create_database" {
#   depends_on = [module.alloydb_primary]
#   provisioner "local-exec" {
#     command     = <<EOF
#       PGPASSWORD="postgres" \
#       psql -h ${module.alloydb_primary.primary_instance.public_ip_address} \
#            -U "${var.cluster_initial_user}" \
#            -p 5432 \
#            -c "CREATE DATABASE ${var.database_name};"
#     EOF
#     interpreter = ["bash", "-c"]
#     environment = {
#       # Set timeout as needed
#       # PGDATABASE = var.database_name
#     }
#   }
# }

