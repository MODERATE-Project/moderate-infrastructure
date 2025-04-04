resource "kubernetes_namespace" "moderate_trust" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "moderate-trust" }
    name        = "trust"
  }
}

locals {
  app_name     = "trust-app"
  namespace    = var.namespace == null ? one(kubernetes_namespace.moderate_trust[*].id) : var.namespace
  trust_port   = 8081
  service_name = "trust-service"
}

resource "random_password" "iota_wallet_stronghold_password" {
  length  = 40
  special = false
}

resource "random_password" "iota_identity_key_storage_stronghold_password" {
  length  = 40
  special = false
}

locals {
  # https://github.com/hashicorp/terraform/issues/23906#issuecomment-1413973319
  dot_env_regex = "(?m:^\\s*([^#\\s]\\S*)\\s*=\\s*[\"']?(.*[^\"'\\s])[\"']?\\s*$)"
  dot_env_data  = { for tuple in regexall(local.dot_env_regex, file("${path.module}/.env.trust")) : tuple[0] => sensitive(tuple[1]) }

  # https://github.com/MODERATE-Project/trust-service/blob/254e06d31f50491544b61d3ff067377dc57fdea3/.env
  secrets_data = {
    MONGO_INITDB_ROOT_USERNAME      = var.mongo_username
    MONGO_INITDB_ROOT_PASSWORD      = var.mongo_password
    MONGO_ENDPOINT                  = var.mongo_endpoint
    MONGO_DATABASE                  = var.mongo_database
    STRONGHOLD_PASSWORD             = random_password.iota_wallet_stronghold_password.result
    KEY_STORAGE_STRONGHOLD_PASSWORD = random_password.iota_identity_key_storage_stronghold_password.result
    L2_PRIVATE_KEY                  = var.l2_private_key
  }

  merged_secrets_data = merge(local.dot_env_data, local.secrets_data)
}

resource "kubernetes_secret" "moderate_trust_secrets" {
  metadata {
    name      = "moderate-trust-secrets"
    namespace = local.namespace
  }

  data = local.merged_secrets_data
}

locals {
  image_tag = "161e7c7a1101423476dad79ed09277091873b3a6"
}

# trunk-ignore(checkov/CKV_K8S_35,checkov/CKV_K8S_8,checkov/CKV_K8S_9)
resource "kubernetes_deployment" "moderate_trust" {
  metadata {
    name      = "trust-deployment"
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
        container {
          image             = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/trust-service:${local.image_tag}"
          name              = "trust"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = local.trust_port
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
              name = kubernetes_secret.moderate_trust_secrets.metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "moderate_trust" {
  metadata {
    name      = local.service_name
    namespace = local.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.moderate_trust.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.trust_port
      target_port = local.trust_port
    }
    type = "ClusterIP"
  }
}
