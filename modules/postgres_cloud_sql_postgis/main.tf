resource "kubernetes_namespace" "enable_postgis" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "postgis-enable-job" }
    name        = "postgis-enable-job"
  }
}

resource "random_password" "job_user_password" {
  length  = 20
  special = false
}

resource "google_sql_user" "sql_user" {
  instance        = var.google_sql_database_instance_name
  name            = "user-job-enable-postgis"
  password        = random_password.job_user_password.result
  deletion_policy = "ABANDON"
}

locals {
  namespace = var.namespace == null ? one(kubernetes_namespace.enable_postgis[*].id) : var.namespace
  pg_user   = google_sql_user.sql_user.name
  pg_pass   = random_password.job_user_password.result
  pg_host   = var.postgres_host
  pg_port   = var.postgres_port
  # By creating the extension in template1, it will be available for all the other databases that are created afterwards.
  pg_db = "template1"
}

resource "kubernetes_secret" "enable_postgis" {
  metadata {
    name      = "secrets-enable-postgis"
    namespace = local.namespace
  }

  data = {
    POSTGRES_URL = "postgres://${local.pg_user}:${local.pg_pass}@${local.pg_host}:${local.pg_port}/${local.pg_db}"
  }
}

resource "kubernetes_job_v1" "enable_postgis" {
  metadata {
    name      = "enable-postgis"
    namespace = local.namespace
  }

  wait_for_completion = false

  spec {
    template {
      metadata {
        labels = {
          app = "enable-postgis"
        }
      }
      spec {
        container {
          name              = "enable-postgis"
          image             = "docker.io/agmangas/moderate-cli:0.2.4"
          image_pull_policy = "Always"
          command = [
            "moderatecli",
            "enable-postgis"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret.enable_postgis.metadata[0].name
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = var.backoff_limit
    completions   = 1
    parallelism   = 1
  }
}
