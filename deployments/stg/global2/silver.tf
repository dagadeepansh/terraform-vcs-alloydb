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
module "alloydb_primary_silver" {
  source = "../../../../terraform-gcp-alloydb"
  project_id     = "cloudlake-dev-1"
  region_primary = "us-central1"
  cluster_id     = "primary-silver-cluster-id"
  cluster_name   = "primary-cluster-silver" 

  psc_enabled                   = true
  psc_attachment_project_number = 805128748265

  # cluster_encryption_key_name = google_kms_crypto_key.key_region_primary.id

  backup_window            = "1800s"
  automated_backup_enabled = true
  weekly_schedule = {
    days_of_week = ["FRIDAY"]
    start_times  = ["02:00:00:000"]
  }
  quantity_based_retention_count = 1
  time_based_retention_count     = null
  backup_labels                  = {test = "alloydb-cluster-silver"} # Use distinct labels

  continuous_backup_recovery_window_days = 10

  primary_instance = {
    instance_id  = "primary-instance-silver-us-central1"
    display_name = "Primary Instance silver (us-central1) "
    #machine_type          = "db-custom-${var.primary_instance.machine_cpu_count}-3840" # Changed interpolation
    availability_type     = "REGIONAL"
    database_flags        = {
          "alloydb.enable_pgaudit"      = "on"
          "alloydb.iam_authentication"  = "on"
           "log_connections"             = "on"
           "log_disconnections"          = "on"
           "log_error_verbosity"         = "default"
           "log_min_duration_statement"  = "-1"
           "log_min_error_statement"     = "error"
           "log_min_messages"            = "warning"
           "log_statement"               = "all"
           "password.enforce_complexity" = "on"
        }
    labels                = {}
    annotations           = {}
    gce_zone              = "us-central1-a" 
    require_connectors    = false
    ssl_mode              = "ENCRYPTED_ONLY" 
    query_insights_config = {
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
      query_plans_per_minute  = 5
  }
    enable_public_ip      = false
    cidr_range            = []
    machine_cpu_count     = 2
  }

  read_pool_instances  = [
  {
    instance_id        = "readpool-instance-us-central1"
    display_name       = "Read Pool Instance (us-central1-f)" # Descriptive name
    node_count         = 1
    database_flags     = {}
    availability_type  = "ZONAL"         # Zonal, in a *different* zone than primary
    gce_zone           = "us-central1-f" # Zone 2 in primary region - MUST be different
    machine_cpu_count  = 2               # Match primary for consistency
    ssl_mode           = "ENCRYPTED_ONLY"
    require_connectors = false
    query_insights_config = {
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
      query_plans_per_minute  = 5
    }
    enable_public_ip = false
    cidr_range       = []
  }
]
  cluster_initial_user = "postgres_primary"
  secret_id            = "primary_postgres_secret"
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