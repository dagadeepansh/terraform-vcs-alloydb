project_id                    = "cloudlake-dev-1"
secret_id                     = "postgres-password-v2"
psc_attachment_project_id     = "terraform-cloudbuild"
psc_attachment_project_number = "805128748265"
region_primary                = "us-central1" # Keeping original value
region_replica                = "us-east4"    # From your provided values
cluster_name                  = "primary-cluster-psc"
cluster_id                    = "primary-central-cluster-id"
backup_window                 = "1800s"    # Keeping original value
automated_backup_enabled      = true       # Keeping original value
cluster_initial_user          = "postgres" # Keeping default from variables.tf

weekly_schedule = {
  days_of_week = ["FRIDAY"]
  start_times  = ["02:00:00:000"] # Using provided corrected format
}

quantity_based_retention_count = 1    # Keeping original value
time_based_retention_count     = null # Keeping original value

backup_labels = {
  test = "alloydb-cluster-with-prim" # Keeping original value
}

continuous_backup_recovery_window_days = 10 # Keeping original value

primary_instance = {
  instance_id        = "cluster-primary-central-instance1-psc" # From your provided values
  display_name       = "Primary Instance"                      # Keeping original value
  database_flags     = {}
  labels             = {
      security_cia = "cia" #  Get user input during plan/apply
      security_pci = "pci" # Get user input during plan/apply
      security_data_confidentiality = "Confidential" # Get user input during plan/apply
  }      # Keeping original value
  annotations        = {}      # Keeping original value
  gce_zone           = null    # Keeping original value
  availability_type  = "ZONAL" # Keeping original value
  machine_cpu_count  = 2       # Using provided cpu_count = 2
  ssl_mode           = "ENCRYPTED_ONLY"
  require_connectors = false # Keeping original value
  query_insights_config = {
    query_string_length     = 1024  # Keeping original value
    record_application_tags = false # Keeping original value
    record_client_address   = false # Keeping original value
    query_plans_per_minute  = 5     # Keeping original value
  }
  enable_public_ip = false # Keeping original value
  cidr_range       = []    # Keeping original value
}

read_pool_instances = [
  {
    instance_id        = "cluster-primary-central-instance1-psc-r1-psc" # Combining primary instance ID and suffix
    display_name       = "Read Pool Instance r1-psc"                    # Clear display name
    node_count         = 1
    database_flags     = {}      # You might want to specify flags here
    availability_type  = "ZONAL" # Or "REGIONAL"
    gce_zone           = null    #  Specify if needed
    machine_cpu_count  = 2       #From the the machine cpu count
    ssl_mode           = "ENCRYPTED_ONLY"
    require_connectors = false # Default
    query_insights_config = {  # Defaults
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
      query_plans_per_minute  = 5
    }
    enable_public_ip = false # Default
    cidr_range       = []    # Default
  },
  {
    instance_id        = "cluster-primary-central-instance1-psc-r2-psc" # Combining primary instance ID and suffix
    display_name       = "Read Pool Instance r2-psc"                    # Clear display name
    node_count         = 2
    database_flags     = {}      # You might want to specify flags here
    availability_type  = "ZONAL" # Or "REGIONAL"
    gce_zone           = null    # Specify if needed
    machine_cpu_count  = 2       #  From the the machine cpu count
    ssl_mode           = "ENCRYPTED_ONLY"
    require_connectors = false # Default
    query_insights_config = {  # Defaults
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
      query_plans_per_minute  = 5
    }
    enable_public_ip = false # Default
    cidr_range       = []    # Default
  }
]

key_suffix_length        = 3                                              # Keeping original value
key_suffix_special       = false                                          # Keeping original value
key_suffix_upper         = false                                          # Keeping original value
alloydb_sa_iam_role      = ["roles/cloudkms.cryptoKeyEncrypterDecrypter"] # Keeping original value
replica_instance_id      = "cluster-replica-east-instance1-psc"           # From your provided values
continuous_backup_enable = true                                           # Keeping original value
cluster_id_replica       = "replica-east-cluster-id"                      # From your provided values
replica_instance = {                                                      # Renamed to avoid conflict
  require_connectors = false
  ssl_mode           = "ENCRYPTED_ONLY"
  machine_cpu_count  = 2
}

security_cia = "cia" #  Get user input during plan/apply

security_pci = "pci" # Get user input during plan/apply

security_data_confidentiality = "Confidential" # Get user input during plan/apply

#psc_vpc_network = "psc-vpc" # Added this