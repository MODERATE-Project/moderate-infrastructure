locals {
  script_name                    = "main.py"
  vol_name                       = "vol-script"
  moderate_realm                 = "moderate"
  apisix_client_id               = "apisix"
  apisix_client_default_resource = "Default Resource"
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
    KEYCLOAK_URL         = var.keycloak_url
    KEYCLOAK_ADMIN_USER  = var.keycloak_admin_user
    KEYCLOAK_ADMIN_PASS  = var.keycloak_admin_pass
    MODERATE_REALM       = local.moderate_realm
    APISIX_CLIENT_ID     = local.apisix_client_id
    APISIX_CLIENT_SECRET = random_password.apisix_client_secret.result
  }
}

resource "kubernetes_config_map" "keycloak_init" {
  metadata {
    name = "config-keycloak-init"
  }

  data = {
    "${local.script_name}" = file("${path.module}/main.py")
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
          name    = "keycloak-init"
          image   = "python:3.10-bullseye"
          command = ["python", "/${local.script_name}"]
          env_from {
            secret_ref {
              name = kubernetes_secret.keycloak_init.metadata[0].name
            }
          }
          volume_mount {
            name       = local.vol_name
            mount_path = "/${local.script_name}"
            sub_path   = local.script_name
          }
        }
        volume {
          name = local.vol_name
          config_map {
            name = kubernetes_config_map.keycloak_init.metadata[0].name
            items {
              key  = local.script_name
              path = local.script_name
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
