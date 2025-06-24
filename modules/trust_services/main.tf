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
    MONGO_ENDPOINT_L                = var.mongo_endpoint
    MONGO_ENDPOINT_D                = var.mongo_endpoint
    MONGO_DATABASE                  = var.mongo_database
    STRONGHOLD_PASSWORD             = random_password.iota_wallet_stronghold_password.result
    KEY_STORAGE_STRONGHOLD_PASSWORD = random_password.iota_identity_key_storage_stronghold_password.result
    L2_PRIVATE_KEY                  = var.l2_private_key
    LOG_FILE_NAME                   = "dlog.log"
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
  image_tag = "cde5ce9e626e26ce1ff7d4f99cd96833e80cef44"
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
          env {
            name  = "RUNNING_IN_DOCKER"
            value = "true"
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

locals {
  ipfs_app_name = "ipfs"
  ipfs_api_port = 5001
}

resource "kubernetes_deployment" "ipfs" {
  metadata {
    name      = "ipfs-deployment"
    namespace = local.namespace
    labels = {
      app = local.ipfs_app_name
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.ipfs_app_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.ipfs_app_name
        }
      }
      spec {
        container {
          image             = "ipfs/kubo:v0.34.1"
          name              = "ipfs"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = local.ipfs_api_port
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }
          volume_mount {
            name       = "ipfs-data"
            mount_path = "/data/ipfs"
          }
        }
        volume {
          name = "ipfs-data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "ipfs" {
  metadata {
    name      = "ipfs"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.ipfs.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.ipfs_api_port
      target_port = local.ipfs_api_port
    }
    type = "ClusterIP"
  }
}
