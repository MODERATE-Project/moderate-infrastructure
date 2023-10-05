resource "kubernetes_namespace" "keycloak_init" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "keycloak-init-job" }
    name        = "keycloak-init-job"
  }
}

locals {
  namespace                           = var.namespace == null ? one(kubernetes_namespace.keycloak_init[*].id) : var.namespace
  vol_name                            = "vol-moderatecli"
  moderate_realm                      = "moderate"
  apisix_client_id                    = "apisix"
  apisix_client_resource_yatai        = "yatai"
  apisix_client_resource_moderate_api = "moderateapi"
  open_metadata_client_id             = "openmetadata"
}

resource "random_password" "apisix_client_secret" {
  length  = 32
  special = false
}

resource "random_password" "open_metadata_client_secret" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "keycloak_init" {
  metadata {
    name      = "secrets-keycloak-init"
    namespace = local.namespace
  }

  data = {
    KEYCLOAK_URL                        = var.keycloak_url
    KEYCLOAK_ADMIN_USER                 = var.keycloak_admin_user
    KEYCLOAK_ADMIN_PASS                 = var.keycloak_admin_pass
    MODERATE_REALM                      = local.moderate_realm
    APISIX_CLIENT_ID                    = local.apisix_client_id
    APISIX_CLIENT_SECRET                = random_password.apisix_client_secret.result
    APISIX_CLIENT_RESOURCE_YATAI        = local.apisix_client_resource_yatai
    APISIX_CLIENT_RESOURCE_MODERATE_API = local.apisix_client_resource_moderate_api
    OPEN_METADATA_CLIENT_ID             = local.open_metadata_client_id
    OPEN_METADATA_CLIENT_SECRET         = random_password.open_metadata_client_secret.result
    OPEN_METADATA_ROOT_URL              = var.open_metadata_root_url
  }
}

locals {
  cli_name = "moderatecli"

  cli_commands = [
    "${local.cli_name} create-keycloak-realm",
    "${local.cli_name} create-apisix-client",
    "${local.cli_name} create-open-metadata-client"
  ]
}

resource "kubernetes_job_v1" "keycloak_init" {
  metadata {
    name      = "keycloak-init"
    namespace = local.namespace
  }

  wait_for_completion = false

  spec {
    template {
      metadata {
        labels = {
          app = "keycloak-init"
        }
      }
      spec {
        container {
          name              = "keycloak-init"
          image             = "docker.io/agmangas/moderate-cli:0.2.4"
          image_pull_policy = "Always"
          command = [
            "/bin/bash",
            "-c",
            join(" && ", local.cli_commands)
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret.keycloak_init.metadata[0].name
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
