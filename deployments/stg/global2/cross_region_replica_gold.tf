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

module "alloydb_replica" {
  source = "../../../../terraform-gcp-alloydb"
  # version = "~> 3.0"

  project_id                    = local.project_id
  region_replica                = local.region_replica
  cluster_id                    = "replica-${local.region_replica}-${local.cluster_id}"
  cluster_name                  = local.cluster_display_name
  security_cia                  = "cia"
  security_pci                  = "pci"
  security_data_confidentiality = "Confidential"

  psc_enabled                   = true
  psc_attachment_project_number = local.psc_project_number

  # cluster_encryption_key_name = google_kms_crypto_key.key_region_primary.id
  backup_window            = "1800s"
  automated_backup_enabled = true
  weekly_schedule = {
    days_of_week = ["FRIDAY"]
    start_times  = ["02:00:00:000"]
  }
  quantity_based_retention_count = 1
  time_based_retention_count     = null
  backup_labels                  = { test = "alloydb-cluster-gold" } # Use distinct labels

  continuous_backup_recovery_window_days = 10

  primary_instance = {
    instance_id  = "replica-${local.region_replica}-${local.cluster_id}-instance1-psc",
    display_name = "Replica Instance Gold (us-central1) "
    #machine_type          = "db-custom-${var.primary_instance.machine_cpu_count}-3840" # Changed interpolation
    availability_type = "REGIONAL"
    database_flags    = {}
    labels = {
      security_cia                  = "cia"          #  Get user input during plan/apply
      security_pci                  = "pci"          # Get user input during plan/apply
      security_data_confidentiality = "Confidential" # Get user input during plan/apply
    }
    annotations        = {}
    gce_zone           = "us-central1-c"
    require_connectors = false
    ssl_mode           = "ENCRYPTED_ONLY"
    query_insights_config = {
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
      query_plans_per_minute  = 5
    }
    enable_public_ip  = false
    cidr_range        = []
    machine_cpu_count = 2
  }

  read_pool_instances = [
    {
      instance_id        = "replica-${local.region_replica}-${local.cluster_id}-instance1-r1-psc",
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
  cluster_initial_user = "postgres_replica"
}