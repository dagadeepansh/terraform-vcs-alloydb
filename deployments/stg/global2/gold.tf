# merged_alloydb_clusters.tf

locals {
  project_id         = "terraform-cloudbuild"
  primary_location   = "northamerica-northeast1"
  region_replica     = "northamerica-northeast2"
  label              = "alloydb-gold"
  psc_project_number = 805128748265

  primary_cluster_id           = "gold-cluster"
  primary_cluster_display_name = "primary-cluster-psc-gold"
  primary_secret_id            = "primary_postgres_secret"
  primary_initial_user         = "postgres"

  replica_cluster_id_suffix    = "replica" # Suffix to differentiate replica cluster ID
  replica_cluster_display_name = "replica-cluster-psc-gold"
  replica_instance_id          = "replica-instance-psc-gold" # Consider making it dynamic if needed
  replica_initial_user         = "postgres_replica"
  security_cia                  = "cia"
  security_pci                  = "pci"
  security_data_confidentiality = "confidential"
}

module "alloydb_primary" {
  source = "../../../../terraform-gcp-alloydb"

  project_id                    = local.project_id
  region_primary                = local.primary_location
  cluster_id                    = local.primary_cluster_id
  cluster_name                  = local.primary_cluster_display_name
  secret_id                     = local.primary_secret_id
  security_cia                  = local.security_cia
  security_pci                  = local.security_pci
  security_data_confidentiality = local.security_data_confidentiality

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
  backup_labels                  = { test = "alloydb-cluster-gold-primary" } # Differentiated label

  continuous_backup_recovery_window_days = 10
  cluster_initial_user                   = local.primary_initial_user

  primary_instance = {
    instance_id  = "${local.primary_cluster_display_name}-instance1-psc"
    display_name = "Primary Instance Gold (us-${local.primary_location})"
    #machine_type          = "db-custom-${var.primary_instance.machine_cpu_count}-3840" # Changed interpolation
    availability_type = "REGIONAL"
    database_flags    = {}
    labels = {
      security_cia                  = local.security_cia
      security_pci                  = local.security_pci
      security_data_confidentiality = local.security_data_confidentiality
    }
    annotations        = {}
    gce_zone           = "${local.primary_location}-a" # Explicit zone in primary region
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
      instance_id        = "${local.primary_cluster_display_name}-instance1-psc-r1-psc"
      display_name       = "Primary Read Pool Instance r1-psc" # Descriptive name
      node_count         = 1
      database_flags     = {}
      availability_type  = "ZONAL"
      gce_zone           = "${local.primary_location}-b" # Zone 2 in primary region - MUST be different
      machine_cpu_count  = 2
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
    },
    {
      instance_id        = "${local.primary_cluster_display_name}-instance1-psc-r2-psc"
      display_name       = "Primary Read Pool Instance r2-psc"
      node_count         = 2
      database_flags     = {}
      availability_type  = "ZONAL"
      gce_zone           = "${local.primary_location}-c" # Zone 3 in primary region
      machine_cpu_count  = 2
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
}

resource "google_alloydb_cluster" "replica" {
  provider                 = google-beta
  project                  = local.project_id
  cluster_id               = "${local.replica_cluster_id_suffix}-${local.region_replica}-${local.primary_cluster_id}"
  location                 = local.region_replica
  display_name             = "${module.alloydb_primary.cluster_name}-replica"
  #primary_cluster_name     = "${module.alloydb_primary.cluster_name}-replica" # Use primary's display name
  cluster_type             = "SECONDARY"

 depends_on = [module.alloydb_primary]
  # initial_user {
  #   password = local.replica_initial_user.password
  #   user     = local.replica_initial_user.user
  # }
  automated_backup_policy {
    enabled = true
    location = local.region_replica != "" ? local.region_replica : null #conditional backup locaiton

    quantity_based_retention {
      count = 1
    }

    time_based_retention {
      retention_period = "3600s" #consistent
    }

    backup_window = "1800s"
    labels        = { test = "alloydb-cluster-gold-replica" }
    encryption_config {
      kms_key_name = google_kms_crypto_key.key_region_replica.id
    }
  }

  continuous_backup_config {
    enabled         = true
    recovery_window_days = 10
      encryption_config {
      kms_key_name = google_kms_crypto_key.key_region_replica.id
    }
  }

  secondary_config {
    primary_cluster_name = module.alloydb_primary.cluster_name
  }

  labels = {
    security_cia                  = local.security_cia
    security_pci                  = local.security_pci
    security_data_confidentiality = local.security_data_confidentiality
  }

  lifecycle {
    ignore_changes = [
      initial_user, # Avoid diffs if managed externally
    ]
  }
}

resource "google_alloydb_instance" "replica_instance" {
  
  #project       = local.project_id
  instance_id   = local.replica_instance_id
  instance_type = "PRIMARY"
  display_name  = "Replica Instance Gold (us-${local.region_replica})"
  cluster       = google_alloydb_cluster.replica.name
  #location      = local.region_replica
  availability_type = "REGIONAL"
  machine_config {
    cpu_count = 2
  }
  labels = {
    security_cia                  = "cia"
    security_pci                  = "pci"
    security_data_confidentiality = "confidential"
  }
  gce_zone           = "${local.region_replica}-a"
  
  depends_on = [google_alloydb_cluster.replica]
  read_pool_config {
     node_count = 0 #Readpool will be created as a different instance
  }

  #require_connectors = false
  #ssl_mode           = "ENCRYPTED_ONLY"
  query_insights_config {
    query_string_length     = 1024
    record_application_tags = false
    record_client_address   = false
    query_plans_per_minute  = 5
  }
}

resource "google_project_service_identity" "alloydb_sa" {
  provider = google-beta
  project  = local.project_id
  service  = "alloydb.googleapis.com"
}

resource "random_string" "key_suffix" {
  length  = 3
  special = false
  upper   = false
}

resource "google_kms_key_ring" "keyring_region_replica" {
  project  = local.project_id
  name     = "keyring-${local.region_replica}-${random_string.key_suffix.result}"
  location = local.region_replica
}

resource "google_kms_crypto_key" "key_region_replica" {
  name     = "key-${local.region_replica}-${random_string.key_suffix.result}"
  key_ring = google_kms_key_ring.keyring_region_replica.id
}

resource "google_kms_crypto_key_iam_member" "alloydb_sa_iam_secondary" {
  crypto_key_id = google_kms_crypto_key.key_region_replica.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.alloydb_sa.email}"
}


# module "alloydb_replica" {
#   source = "../../../../terraform-gcp-alloydb"
#   # version = "~> 3.0"
  
#   primary_cluster_name          = module.alloydb_primary.cluster_name
#   project_id                    = local.project_id
#   region_replica                = local.region_replica
#   cluster_id                    = "${local.replica_cluster_id_suffix}-${local.region_replica}-${local.primary_cluster_id}" # Differentiated cluster ID                                         # Consider making it dynamic if needed
#   cluster_name                  = "${module.alloydb_primary.cluster_name}-replica"
#   cluster_type                  = "SECONDARY"
#   security_cia                  = "cia"
#   security_pci                  = "pci"
#   security_data_confidentiality = "confidential"

#   psc_enabled                   = true
#   psc_attachment_project_number = local.psc_project_number

#   # cluster_encryption_key_name = google_kms_crypto_key.key_region_primary.id
#   backup_window            = "1800s"
#   automated_backup_enabled = true
#   weekly_schedule = {
#     days_of_week = ["FRIDAY"]
#     start_times  = ["02:00:00:000"]
#   }
#   quantity_based_retention_count = 1
#   time_based_retention_count     = null
#   backup_labels                  = { test = "alloydb-cluster-gold-replica" } # Differentiated label

#   continuous_backup_recovery_window_days = 10
#   cluster_initial_user                   = local.replica_initial_user

#   replica_instance_id      = "${local.replica_cluster_id_suffix}-${local.region_replica}-${local.primary_cluster_id}-instance1-psc" # Define replica instance ID here for clarity
#   continuous_backup_enable = true                                                                                                   # Assuming you want continuous backup enabled for replica as well

#   replica_instance = {                       # Configuration for the replica instance itself
#     instance_id  = local.replica_instance_id # Use the defined replica instance ID
#     display_name = "Replica Instance Gold (us-${local.region_replica})"
#     #machine_type          = "db-custom-${var.primary_instance.machine_cpu_count}-3840" # Changed interpolation
#     availability_type = "REGIONAL"
#     database_flags    = {}
#     labels = {
#       security_cia                  = "cia"
#       security_pci                  = "pci"
#       security_data_confidentiality = "Confidential" # You had "confidential" in primary, "Confidential" in replica - consistent to "confidential"
#     }
#     annotations        = {}
#     gce_zone           = "${local.region_replica}-a" # Zone in replica region
#     require_connectors = false
#     ssl_mode           = "ENCRYPTED_ONLY"
#     query_insights_config = {
#       query_string_length     = 1024
#       record_application_tags = false
#       record_client_address   = false
#       query_plans_per_minute  = 5
#     }
#     enable_public_ip  = false
#     cidr_range        = []
#     machine_cpu_count = 2
#   }

#   read_pool_instances = [ # Read pool for replica cluster (if needed)
#     {
#       instance_id        = "${local.replica_instance_id}-r1-psc"                       # Based on replica instance ID
#       display_name       = "Replica Read Pool Instance (us-${local.region_replica}-f)" # Descriptive name
#       node_count         = 1
#       database_flags     = {}
#       availability_type  = "ZONAL"
#       gce_zone           = "${local.region_replica}-b" # Zone in replica region, different from instance
#       machine_cpu_count  = 2
#       ssl_mode           = "ENCRYPTED_ONLY"
#       require_connectors = false
#       query_insights_config = {
#         query_string_length     = 1024
#         record_application_tags = false
#         record_client_address   = false
#         query_plans_per_minute  = 5
#       }
#       enable_public_ip = false
#       cidr_range       = []
#     }
#   ]

# }

# resource "google_project_service_identity" "alloydb_sa" {
#   provider = google-beta
#   project  = local.project_id
#   service  = "alloydb.googleapis.com"
# }
# resource "random_string" "key_suffix" {
#   length  = 3
#   special = false
#   upper   = false
# }
# resource "google_kms_key_ring" "keyring_region_replica" {
#   project  = local.project_id
#   name     = "keyring-${local.region_replica}-${random_string.key_suffix.result}"
#   location = local.region_replica
# }

# resource "google_kms_crypto_key" "key_region_replica" {
#   name     = "key-${local.region_replica}-${random_string.key_suffix.result}"
#   key_ring = google_kms_key_ring.keyring_region_replica.id
# }

# resource "google_kms_crypto_key_iam_member" "alloydb_sa_iam_secondary" {
#   crypto_key_id = google_kms_crypto_key.key_region_replica.id
#   role          = join(",", ["roles/cloudkms.cryptoKeyEncrypterDecrypter"])
#   member        = "serviceAccount:${google_project_service_identity.alloydb_sa.email}"
# }