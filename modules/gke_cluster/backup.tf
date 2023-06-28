resource "google_gke_backup_backup_plan" "gke_backup_plan" {
  name        = "gke-backup-plan"
  cluster     = module.gke.cluster_id
  location    = var.region
  deactivated = var.enable_backup ? false : true

  backup_config {
    include_volume_data = true
    include_secrets     = true
    all_namespaces      = true
  }

  backup_schedule {
    cron_schedule = var.backup_cron_schedule
    paused        = var.enable_backup ? false : true
  }

  retention_policy {
    backup_delete_lock_days = var.backup_delete_lock_days
    backup_retain_days      = var.backup_retain_days
  }
}
