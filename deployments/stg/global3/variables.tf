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

variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
  default     = "cloudlake-dev-1"
}

variable "psc_attachment_project_id" {
  description = "The ID of the project in which attachment will be provisioned"
  type        = string
  default     = "terraform-cloudbuild"
}

variable "psc_attachment_project_number" {
  description = "The project number in which attachment will be provisioned"
  type        = string
  default     = "805128748265"
}

variable "region_primary" {
  description = "The region for cluster in central us"
  type        = string
  default     = "us-central1"
}

variable "region_replica" {
  description = "The region for cluster in east us"
  type        = string
  default     = "us-east1"
}

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "primary-cluster-psc"
}

variable "cluster_id" {
  type        = string
  description = "The ID of the AlloyDB cluster."
  default     = "primary-central-cluster-id"
}

variable "psc_enabled" {
  type        = bool
  description = "Whether to enable PSC for the cluster."
  default     = true
}

variable "psc_vpc_network" {
  type        = string
  description = "The name of the VPC network for PSC."
  default     = "psc-vpc"
}

variable "backup_window" {
  type        = string
  description = "The backup window time (e.g., 1800s)."
  default     = "1800s"
}

variable "automated_backup_enabled" {
  type        = bool
  description = "Whether automated backup is enabled."
  default     = true
}

variable "cluster_initial_user" {
  type        = string
  description = "The initial user for the cluster."
  default     = "postgres"
}

variable "weekly_schedule" {
  type = object({
    days_of_week = list(string)
    start_times  = list(string)
  })
  description = "The weekly schedule for backups."
  default = {
    days_of_week = ["Friday"]
    start_times  = ["03:00:00:000"]
  }
}

variable "quantity_based_retention_count" {
  type        = number
  description = "The number of backups to retain based on quantity."
  default     = 1
}

variable "time_based_retention_count" {
  type        = number
  description = "The number of backups to retain based on time."
  default     = null
}

variable "backup_labels" {
  type        = map(string)
  description = "Labels to apply to the backups."
  default = {
    test = "alloydb-cluster-with-prim"
  }
}

variable "continuous_backup_recovery_window_days" {
  type        = number
  description = "The number of days for the continuous backup recovery window."
  default     = 10
}

# variable "primary_instance_id" {
#   type        = string
#   description = "Primary instance id name"
#   default     = "cluster-primary-central-instance1-psc"
# }

variable "primary_instance" {
  type = object({
    instance_id        = string
    display_name       = string
    database_flags     = map(string)
    labels             = map(string)
    annotations        = map(string)
    gce_zone           = string
    availability_type  = string
    machine_cpu_count  = number
    ssl_mode           = string
    require_connectors = bool
    query_insights_config = object({
      query_string_length     = number
      record_application_tags = bool
      record_client_address   = bool
      query_plans_per_minute  = number
    })
    enable_public_ip = bool
    cidr_range       = list(string)
  })
  default = {
    instance_id        = "default-instance-id" // Good practice to provide defaults
    display_name       = "Default Instance"
    database_flags     = {}
    labels             = {}
    annotations        = {}
    gce_zone           = null    //  Use null for optional values
    availability_type  = "ZONAL" // Or "REGIONAL"
    machine_cpu_count  = 2
    ssl_mode           = "ENCRYPTED_ONLY"
    require_connectors = false
    query_insights_config = {
      query_string_length     = 1024 // Default
      record_application_tags = false
      record_client_address   = false
      query_plans_per_minute  = 5 // Default
    }
    enable_public_ip = false
    cidr_range       = []
  }

  validation {
    condition = alltrue([
      var.primary_instance.ssl_mode == null || var.primary_instance.ssl_mode == "ENCRYPTED_ONLY"
    ])
    error_message = "The ssl_mode for each read pool instance must be \"ENCRYPTED_ONLY\" or be left unset (null) to use the module's default."
  }
  validation {
    condition     = can(regex("^(2|4|8|16|32|64|96|128)$", tostring(var.primary_instance.machine_cpu_count)))
    error_message = "machine_cpu_count must be one of [2, 4, 8, 16, 32, 64, 96, 128]"
  }
  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", var.primary_instance.instance_id))
    error_message = "Primary Instance ID should satisfy the following pattern ^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$"
  }
  validation {
    condition = var.primary_instance.query_insights_config == null || (
      var.primary_instance.query_insights_config.query_string_length >= 256 &&
      var.primary_instance.query_insights_config.query_string_length <= 4500
    )
    error_message = "Query string length must be between 256 and 4500. The default value is 1024."
  }
  validation {
    condition = var.primary_instance.query_insights_config == null || (
      var.primary_instance.query_insights_config.query_plans_per_minute >= 0 &&
      var.primary_instance.query_insights_config.query_plans_per_minute <= 20
    )
    error_message = "Query plans per minute must be between 0 and 20. The default value is 5."
  }
}

variable "read_pool_instances" {
  type = list(object({
    instance_id        = string
    display_name       = string
    node_count         = number
    database_flags     = map(string)
    availability_type  = string
    gce_zone           = string // Corrected typo: tring -> string
    machine_cpu_count  = number
    ssl_mode           = string
    require_connectors = bool
    query_insights_config = object({
      query_string_length     = number
      record_application_tags = bool
      record_client_address   = bool
      query_plans_per_minute  = number
    })
    enable_public_ip = bool
    cidr_range       = list(string)
  }))
  default     = [] // Default to an empty list (good choice for optional read pools)
  description = "Read pool instance configurations."

  validation {
    condition = alltrue([
      for inst in var.read_pool_instances :
      inst.ssl_mode == null || inst.ssl_mode == "ENCRYPTED_ONLY"
    ])
    error_message = "The ssl_mode for each read pool instance must be \"ENCRYPTED_ONLY\" or be left unset (null) to use the module's default."
  }
  validation {
    condition = alltrue([
      for instance in var.read_pool_instances :                                                      // Corrected:  var.read_pool_instances
      contains(["2", "4", "8", "16", "32", "64", "96", "128"], tostring(instance.machine_cpu_count)) // Corrected: instance.machine_cpu_count
    ])
    error_message = "machine_cpu_count in read_pool_instances must be one of [2, 4, 8, 16, 32, 64, 96, 128]"
  }
  validation {
    condition = var.read_pool_instances == null || alltrue([
      for instance in var.read_pool_instances : contains(["ZONAL", "REGIONAL"], tostring(instance.availability_type))
    ])
    error_message = "availability_type in read_pool_instances must be ZONAL or REGIONAL."
  }
}
variable "key_suffix_length" {
  type        = number
  description = "The length of the random suffix for KMS key and key ring names."
  default     = 3
}

variable "key_suffix_special" {
  type        = bool
  description = "Whether to include special characters in the random suffix."
  default     = false
}

variable "key_suffix_upper" {
  type        = bool
  description = "Whether to include uppercase characters in the random suffix."
  default     = false
}

variable "alloydb_sa_iam_role" {
  type        = list(string)
  description = "The IAM role to assign to the AlloyDB service account."
  default     = ["roles/cloudkms.cryptoKeyEncrypterDecrypter"]
}

variable "replica_instance_id" {
  type        = string
  description = "The ID of the primary instance for the cross-region replica cluster."
  default     = "cluster-replica-east-instance1-psc"
}

variable "continuous_backup_enable" {
  type        = bool
  description = "Whether to enable continuous backup for the replica cluster."
  default     = true
}

variable "cluster_id_replica" {
  type        = string
  description = "The ID of the AlloyDB cluster in the east region."
  default     = "cluster-replica-psc"
}

variable "replica_instance" {
  type = object({
    require_connectors = bool
    ssl_mode           = string
    machine_cpu_count  = number
  })
  description = "Replica primary instance configuration."
  default = {
    require_connectors = false
    ssl_mode           = "ENCRYPTED_ONLY"
    machine_cpu_count  = 2
  }

  validation {
    condition = alltrue([
      var.replica_instance.ssl_mode == null || var.replica_instance.ssl_mode == "ENCRYPTED_ONLY"
    ])
    error_message = "The ssl_mode for each read pool instance must be \"ENCRYPTED_ONLY\" or be left unset (null) to use the module's default."
  }
}
variable "cluster_depends_on" {
  type    = any
  default = []
}

variable "replica_gce_zone" {
  type        = string
  description = "The zone to place the replica instance."
  default     = "" // Make sure the user sets it.
}

variable "create_replica_cluster" {
  type        = bool
  description = "Whether to create a cross-region replica cluster."
  default     = false # Default to NOT creating a replica
}

variable "database_name" {
  type        = string
  description = "The name of the database to create."
  default     = "pg_test_db"
}

variable "cluster_initial_username" {
  type        = string
  description = "The name of the database user."
  default     = "pg_test_db"
}
