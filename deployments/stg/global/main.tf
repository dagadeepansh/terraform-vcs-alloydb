/**
 * Copyright 2023 Google LLC
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
  #cluster_id       = "cluster-${var.region_primary}-psc"
  project_id           = var.project_id
  cluster_location     = var.region_primary
  cluster_id           = var.cluster_id
  cluster_display_name = var.cluster_name

  psc_enabled                   = var.psc_enabled
  psc_allowed_consumer_projects = [var.psc_attachment_project_number]

  cluster_encryption_key_name = google_kms_crypto_key.key_region_primary.id

  automated_backup_policy = {
    location      = var.region_primary
    backup_window = var.backup_window
    enabled       = var.automated_backup_enabled
    weekly_schedule = {
      days_of_week = var.weekly_schedule.days_of_week
      start_times  = var.weekly_schedule.start_times
    }
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
    machine_type          = "db-custom-${var.primary_instance.machine_cpu_count}-3840" # Changed interpolation
    availability_type     = var.primary_instance.availability_type
    database_flags        = local.merged_database_flags
    labels                = var.primary_instance.labels
    annotations           = var.primary_instance.annotations
    gce_zone              = var.primary_instance.gce_zone
    require_connectors    = var.primary_instance.require_connectors
    ssl_mode              = var.primary_instance.ssl_mode
    query_insights_config = var.primary_instance.query_insights_config
    enable_public_ip      = var.primary_instance.enable_public_ip
    cidr_range            = var.primary_instance.cidr_range
    machine_cpu_count     = var.primary_instance.machine_cpu_count
  }

  read_pool_instance = [
    for _, read_instance in var.read_pool_instances : {
      instance_id           = read_instance.instance_id
      display_name          = read_instance.display_name
      node_count            = read_instance.node_count
      machine_type          = "db-custom-${read_instance.machine_cpu_count}-3840" # Changed interpolation
      availability_type     = read_instance.availability_type
      database_flags        = read_instance.database_flags
      gce_zone              = read_instance.gce_zone
      require_connectors    = var.primary_instance.require_connectors
      ssl_mode              = var.primary_instance.ssl_mode
      query_insights_config = read_instance.query_insights_config
      enable_public_ip      = read_instance.enable_public_ip
      cidr_range            = read_instance.cidr_range
      machine_cpu_count     = read_instance.machine_cpu_count
    }
  ]

  depends_on = [
    google_kms_crypto_key_iam_member.alloydb_sa_iam,
    google_kms_crypto_key.key_region_primary,
  ]
  cluster_initial_user = {
    user     = var.cluster_initial_user
    password = google_secret_manager_secret_version.alloydb_secret_version.secret_data
  }

}

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

resource "google_project_service_identity" "alloydb_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "alloydb.googleapis.com"
}
resource "random_string" "key_suffix" {
  length  = var.key_suffix_length
  special = var.key_suffix_special
  upper   = var.key_suffix_upper
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


## Cross Region Secondary Cluster Keys

resource "google_kms_key_ring" "keyring_region_replica" {
  project  = var.project_id
  name     = "keyring-${var.region_replica}-${random_string.key_suffix.result}"
  location = var.region_replica
}

resource "google_kms_crypto_key" "key_region_replica" {
  name     = "key-${var.region_replica}-${random_string.key_suffix.result}"
  key_ring = google_kms_key_ring.keyring_region_replica.id
}

resource "google_kms_crypto_key_iam_member" "alloydb_sa_iam_secondary" {
  crypto_key_id = google_kms_crypto_key.key_region_replica.id
  role          = join(",", var.alloydb_sa_iam_role)
  member        = "serviceAccount:${google_project_service_identity.alloydb_sa.email}"
}


resource "google_alloydb_cluster" "replica_cluster" {
  count = var.create_replica_cluster ? 1 : 0

  #name = module.alloydb_primary.cluster_name ## Comment this line to promote this cluster as primary cluster

  cluster_id = var.cluster_id_replica
  location   = var.region_replica
  project    = var.project_id

  continuous_backup_config {
    enabled              = var.continuous_backup_enable
    recovery_window_days = var.continuous_backup_recovery_window_days
  }
  encryption_config {
    kms_key_name = google_kms_crypto_key.key_region_replica.id
  }
}

resource "google_alloydb_instance" "replica_instance" {
  count = var.create_replica_cluster ? 1 : 0

  #cluster          = module.alloydb_primary.replica_cluster[0].name 
  cluster       = google_alloydb_cluster.replica_cluster[0].name
  instance_id   = var.replica_instance_id
  instance_type = "READ_POOL"

  machine_config {
    cpu_count = var.primary_instance.machine_cpu_count # Take CPU from primary instance variable
  }

  availability_type = "ZONAL"
  gce_zone          = var.replica_gce_zone

  depends_on = [
    module.alloydb_primary,
    google_kms_crypto_key_iam_member.alloydb_sa_iam_secondary,
    google_kms_crypto_key.key_region_replica,
  ]
}

resource "random_password" "initial_user_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "alloydb_secret" {
  secret_id = "alloydb-initial-user-password"
  project = var.project_id
  replication {
    auto{} # Replicate the secret automatically to all regions
  }
}

resource "google_secret_manager_secret_version" "alloydb_secret_version" {
  secret      = google_secret_manager_secret.alloydb_secret.id
  secret_data = random_password.initial_user_password.result
}