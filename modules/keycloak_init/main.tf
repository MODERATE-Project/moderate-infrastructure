locals {
  vol_name                            = "vol-moderatecli"
  moderate_realm                      = "moderate"
  apisix_client_id                    = "apisix"
  apisix_client_resource_yatai        = "yatai"
  apisix_client_resource_moderate_api = "moderateapi"
}

resource "random_password" "apisix_client_secret" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "keycloak_init" {
  metadata {
    name = "secrets-keycloak-init"
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
  }
}

resource "kubernetes_job_v1" "keycloak_init" {
  metadata {
    name = "keycloak-init"
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
          image             = "docker.io/agmangas/moderate-cli:latest"
          image_pull_policy = "Always"
          command = [
            "moderatecli",
            "create-keycloak-entities"
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
