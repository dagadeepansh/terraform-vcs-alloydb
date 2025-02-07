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
  source = "../../../../terraform-gcp-alloydb"
  # version = "~> 3.0"
  project_id     = var.project_id
  region_primary = var.region_primary
  cluster_id     = var.cluster_id
  cluster_name   = var.cluster_name

  psc_enabled                   = var.psc_enabled
  psc_attachment_project_number = var.psc_attachment_project_number

  # cluster_encryption_key_name = google_kms_crypto_key.key_region_primary.id

  backup_window            = var.backup_window
  automated_backup_enabled = var.automated_backup_enabled
  weekly_schedule = {
    days_of_week = var.weekly_schedule.days_of_week
    start_times  = var.weekly_schedule.start_times
  }
  quantity_based_retention_count = var.quantity_based_retention_count
  time_based_retention_count     = var.time_based_retention_count
  backup_labels                  = var.backup_labels

  continuous_backup_recovery_window_days = var.continuous_backup_recovery_window_days

  primary_instance = {
    instance_id  = var.primary_instance.instance_id
    display_name = var.primary_instance.display_name
    #machine_type          = "db-custom-${var.primary_instance.machine_cpu_count}-3840" # Changed interpolation
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
    machine_cpu_count     = var.primary_instance.machine_cpu_count
  }

  read_pool_instances  = var.read_pool_instances
  cluster_initial_user = var.cluster_initial_user
  secret_id            = var.primary_secret_id
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