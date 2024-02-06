resource "kubernetes_namespace" "moderate_api" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "moderate-api" }
    name        = "api"
  }
}

locals {
  app_name        = "api-app"
  namespace       = var.namespace == null ? one(kubernetes_namespace.moderate_api[*].id) : var.namespace
  api_port        = 8000
  service_name    = "api-service"
  postgres_port   = 5432
  s3_endpoint_url = "https://storage.googleapis.com"
  s3_region       = "auto"
}

resource "random_password" "password_db" {
  length  = 20
  special = false
}

resource "google_sql_user" "sql_user" {
  instance        = var.cloud_sql_instance_name
  name            = "moderateapi"
  password        = random_password.password_db.result
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "sql_database" {
  instance = var.cloud_sql_instance_name
  name     = "moderateapi"
}

resource "kubernetes_secret" "moderate_api_secrets" {
  metadata {
    name      = "moderate-api-secrets"
    namespace = local.namespace
  }

  data = {
    # https://cloud.google.com/storage/docs/aws-simple-migration
    MODERATE_API_S3__ACCESS_KEY              = google_storage_hmac_key.api_bucket_hmac_key.access_id
    MODERATE_API_S3__SECRET_KEY              = google_storage_hmac_key.api_bucket_hmac_key.secret
    MODERATE_API_S3__ENDPOINT_URL            = local.s3_endpoint_url
    MODERATE_API_S3__USE_SSL                 = "true"
    MODERATE_API_S3__REGION                  = local.s3_region
    MODERATE_API_S3__BUCKET                  = module.bucket.buckets_map[local.api_bucket_name].name
    MODERATE_API_POSTGRES_URL                = "postgresql+asyncpg://${google_sql_user.sql_user.name}:${google_sql_user.sql_user.password}@localhost:${local.postgres_port}/${google_sql_database.sql_database.name}"
    MODERATE_API_TRUST_SERVICE__ENDPOINT_URL = var.trust_service_endpoint_url
  }
}

module "cloud_sql_proxy_wi" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version    = "~> 29.0.0"
  name       = "cloud-sql-proxy-moderateapi"
  namespace  = local.namespace
  project_id = var.project_id
  roles      = ["roles/cloudsql.client"]
}

# trunk-ignore(checkov/CKV_K8S_35)
resource "kubernetes_deployment" "moderate_api" {
  metadata {
    name      = "api-deployment"
    namespace = local.namespace
    labels = {
      app = local.app_name
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.app_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.app_name
        }
      }
      spec {
        service_account_name = module.cloud_sql_proxy_wi.k8s_service_account_name
        container {
          image             = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/moderate-api:latest"
          name              = "api"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = local.api_port
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.moderate_api_secrets.metadata[0].name
            }
          }
          readiness_probe {
            http_get {
              path = "/ping"
              port = local.api_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          liveness_probe {
            http_get {
              path = "/ping"
              port = local.api_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 6
          }
        }
        container {
          image             = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.6"
          name              = "cloudsql-proxy"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          args = [
            "--private-ip",
            "--structured-logs",
            "--port=${local.postgres_port}",
            "${var.cloud_sql_instance_connection_name}"
          ]
          port {
            container_port = local.postgres_port
          }
          resources {
            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "moderate_api" {
  metadata {
    name      = local.service_name
    namespace = local.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.moderate_api.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.api_port
      target_port = local.api_port
    }
    type = "ClusterIP"
  }
}
