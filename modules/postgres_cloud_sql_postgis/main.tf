resource "random_password" "job_user_password" {
  length = 20
}

resource "google_sql_user" "sql_user" {
  instance        = var.google_sql_database_instance_name
  name            = "user-job-enable-postgis"
  password        = random_password.job_user_password.result
  deletion_policy = "ABANDON"
}

locals {
  pg_user = google_sql_user.sql_user.name
  pg_pass = random_password.job_user_password.result
  pg_host = var.postgres_host
  pg_port = var.postgres_port
  # By creating the extension in template1, it will be available for all the other databases that are created afterwards.
  pg_db = "template1"
}

resource "kubernetes_secret" "enable_postgis" {
  metadata {
    name = "secrets-enable-postgis"
  }

  data = {
    POSTGRES_URL = "postgres://${local.pg_user}:${local.pg_pass}@${local.pg_host}:${local.pg_port}/${local.pg_db}"
  }
}

locals {
  script_name = "main.py"
}

resource "kubernetes_config_map" "enable_postgis" {
  metadata {
    name = "config-enable-postgis"
  }

  data = {
    "${local.script_name}" = file("${path.module}/main.py")
  }
}

resource "kubernetes_job_v1" "enable_postgis" {
  metadata {
    name = "enable-postgis"
  }
  spec {
    template {
      metadata {
        labels = {
          app = "enable-postgis"
        }
      }
      spec {
        container {
          name    = "enable-postgis"
          image   = "python:3.10-bullseye"
          command = ["python", "/${local.script_name}"]
          env_from {
            secret_ref {
              name = kubernetes_secret.enable_postgis.metadata[0].name
            }
          }
          volume_mount {
            name       = "vol-script"
            mount_path = "/${local.script_name}"
            sub_path   = local.script_name
          }
        }
        volume {
          name = "vol-script"
          config_map {
            name = kubernetes_config_map.enable_postgis.metadata[0].name
            items {
              key  = local.script_name
              path = local.script_name
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 10
  }
}
