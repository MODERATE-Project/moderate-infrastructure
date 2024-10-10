resource "kubernetes_namespace" "enable_extensions" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "enable-extensions-${var.database}" }
    name        = "enable-extensions-${var.database}"
  }
}

resource "random_password" "job_user_password" {
  length  = 20
  special = false
}

resource "google_sql_user" "sql_user" {
  instance        = var.google_sql_database_instance_name
  name            = "user-job-enable-extensions-${var.database}"
  password        = random_password.job_user_password.result
  deletion_policy = "ABANDON"
}

locals {
  namespace = var.namespace == null ? one(kubernetes_namespace.enable_extensions[*].id) : var.namespace
  pg_user   = google_sql_user.sql_user.name
  pg_pass   = random_password.job_user_password.result
  pg_host   = var.postgres_host
  pg_port   = var.postgres_port
  pg_db     = var.database
}

resource "kubernetes_secret" "enable_extensions" {
  metadata {
    name      = "secrets-enable-extensions"
    namespace = local.namespace
  }

  data = {
    POSTGRES_URL = "postgres://${local.pg_user}:${local.pg_pass}@${local.pg_host}:${local.pg_port}/${local.pg_db}"
  }
}

resource "kubernetes_job_v1" "enable_extensions" {
  metadata {
    name      = "enable-extensions"
    namespace = local.namespace
  }

  wait_for_completion = false

  spec {
    template {
      metadata {
        labels = {
          app = "enable-extensions"
        }
      }
      spec {
        container {
          name              = "enable-extensions"
          image             = "docker.io/agmangas/moderate-cli:0.6.0"
          image_pull_policy = "Always"
          command = [
            "moderatecli",
            "enable-extensions"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret.enable_extensions.metadata[0].name
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
