# https://cloud.google.com/sql/docs/postgres/configure-private-ip#new-private-instance

resource "google_compute_global_address" "postgres_private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.cluster_network_id
}

resource "google_service_networking_connection" "default" {
  network                 = var.cluster_network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.postgres_private_ip_address.name]
  # https://github.com/hashicorp/terraform-provider-google/issues/16275#issuecomment-1825752152
  provider = google-beta
}

resource "google_sql_database_instance" "postgres_sql_instance" {
  depends_on = [
    google_service_networking_connection.default
  ]

  project             = var.project_id
  region              = var.region
  name                = "moderate-postgres"
  database_version    = var.database_version
  deletion_protection = false

  settings {
    tier                  = "db-g1-small"
    availability_type     = "ZONAL"
    disk_size             = var.disk_size_gb
    disk_autoresize_limit = var.disk_autoresize_limit

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      location                       = var.region
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.cluster_network_id
      enable_private_path_for_google_cloud_services = true
    }
  }
}
