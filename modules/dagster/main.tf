resource "kubernetes_namespace" "dagster" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "dagster" }
    name        = "dagster"
  }
}

locals {
  namespace = var.namespace == null ? one(kubernetes_namespace.dagster[*].id) : var.namespace
}

resource "random_password" "password_dagster_sql_user" {
  length  = 20
  special = false
}

resource "google_sql_user" "dagster_sql_user" {
  instance        = var.cloud_sql_instance_name
  name            = "dagster"
  password        = random_password.password_dagster_sql_user.result
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "sql_database_dagster" {
  instance = var.cloud_sql_instance_name
  name     = "dagster"
}

resource "google_sql_database" "sql_database_building_stock" {
  instance = var.cloud_sql_instance_name
  name     = "building_stock_analysis"
}

resource "kubernetes_secret" "dagster_secrets" {
  metadata {
    name      = "dagster-secrets"
    namespace = local.namespace
  }

  data = {
    KEYCLOAK_SERVER_URL     = var.keycloak_url
    KEYCLOAK_ADMIN_USERNAME = var.keycloak_admin_user
    KEYCLOAK_ADMIN_PASSWORD = var.keycloak_admin_pass
    POSTGRES_HOST           = var.postgres_host
    POSTGRES_PORT           = var.postgres_port
    POSTGRES_USERNAME       = google_sql_user.dagster_sql_user.name
    POSTGRES_PASSWORD       = google_sql_user.dagster_sql_user.password
    OPEN_METADATA_HOST      = var.open_metadata_host
    OPEN_METADATA_PORT      = var.open_metadata_port
    OPEN_METADATA_TOKEN     = var.open_metadata_token
    API_BASE_URL            = var.platform_api_url
    API_USERNAME            = var.platform_api_username
    API_PASSWORD            = var.platform_api_password
    S3_ACCESS_KEY_ID        = var.s3_access_key
    S3_SECRET_ACCESS_KEY    = var.s3_secret_key
    S3_REGION               = "auto"
    S3_BUCKET_NAME          = var.s3_bucket_name
    S3_ENDPOINT_URL         = "https://storage.googleapis.com"
  }
}

locals {
  dagster_config = {
    "ingress" = {
      "enabled"          = var.ingress_enabled
      "ingressClassName" = "nginx"
      "annotations" : {
        "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
      }
      "dagsterWebserver" = {
        "path"     = "/"
        "pathType" = "Prefix"
        "host"     = var.domain
        "tls" = {
          "enabled"    = true
          "secretName" = "dagster-ingress-tls-secret"
        }
      }
    },
    "postgresql" = {
      "enabled"            = false
      "postgresqlHost"     = var.postgres_host
      "postgresqlUsername" = google_sql_user.dagster_sql_user.name
      "postgresqlPassword" = google_sql_user.dagster_sql_user.password
      "postgresqlDatabase" = google_sql_database.sql_database_dagster.name
      "service" = {
        "port" = var.postgres_port
      }
    },
    "dagster-user-deployments" = {
      "enabled" = true
      "deployments" = [{
        "name" = "moderate-user-deployment"
        "image" = {
          "repository" = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/moderate-workflows"
          "tag"        = "latest"
          "pullPolicy" = "Always"
        }
        "dagsterApiGrpcArgs" = [
          "--package-name",
          "moderate"
        ]
        "port" = 3030
        "resources" = {
          "requests" = {
            "cpu"    = "100m"
            "memory" = "256Mi"
          }
        }
        "envSecrets" = [{
          "name" = kubernetes_secret.dagster_secrets.metadata[0].name
        }]
      }]
    }
  }
}

resource "helm_release" "dagster" {
  lifecycle {
    replace_triggered_by = [kubernetes_secret.dagster_secrets]
  }

  depends_on = [google_sql_database.sql_database_building_stock]
  name       = "dagster"
  repository = "https://dagster-io.github.io/helm"
  chart      = "dagster"
  version    = var.dagster_chart_version
  namespace  = local.namespace
  values     = [yamlencode(local.dagster_config)]
}
