module "alloydb_replica" {
  source = "../../terraform-gcp-alloydb"

  cluster_id       = var.cluster_id_replica
  project_id       = var.project_id

  psc_enabled                   = var.psc_enabled
  attachment_project_number = [var.attachment_project_number]

  primary_instance = {
    instance_id           = var.replica_instance_id,
    display_name          = var.primary_instance.display_name
    database_flags        = var.primary_instance.database_flags
    labels                = var.primary_instance.labels
    annotations           = var.primary_instance.annotations
    gce_zone              = var.primary_instance.gce_zone
    availability_type     = var.primary_instance.availability_type
    machine_type          = "db-custom-${var.primary_instance.machine_cpu_count}-3840" # Assuming you want the same machine type as primary
    ssl_mode              = var.primary_instance.ssl_mode
    require_connectors    = var.primary_instance.require_connectors
    query_insights_config = var.primary_instance.query_insights_config
    enable_public_ip      = var.primary_instance.enable_public_ip
    cidr_range            = var.primary_instance.cidr_range
  }

  continuous_backup_enable               = var.continuous_backup_enable
  continuous_backup_recovery_window_days = var.continuous_backup_recovery_window_days

  depends_on = [
    module.alloydb_primary,
    google_kms_crypto_key_iam_member.alloydb_sa_iam_secondary,
    google_kms_crypto_key.key_region_replica,
  ]
}
