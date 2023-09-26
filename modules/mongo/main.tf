resource "kubernetes_namespace" "mongo" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "mongo" }
    name        = "mongo"
  }
}

locals {
  app_name   = "mongo-app"
  namespace  = var.namespace == null ? one(kubernetes_namespace.mongo[*].id) : var.namespace
  mongo_port = 27017
}

resource "kubernetes_persistent_volume_claim" "mongo_pvc" {
  metadata {
    name      = "mongo-pvc"
    namespace = local.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.volume_size_gi}Gi"
      }
    }
  }
  wait_until_bound = false
}

// trunk-ignore(terrascan/AC_K8S_0064)
resource "kubernetes_deployment" "mongo" {
  metadata {
    name      = "mongo-deployment"
    namespace = local.namespace
    labels = {
      app = local.app_name
    }
  }
  spec {
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
          image             = "mongo:7.0"
          name              = "mongo"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = local.mongo_port
          }
          volume_mount {
            name       = "data-volume"
            mount_path = "/data/db"
          }
          resources {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2048Mi"
            }
          }
          liveness_probe {
            exec {
              command = ["mongosh", "--eval", "db.adminCommand('ping')"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = ["mongosh", "--eval", "db.adminCommand('ping')"]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        volume {
          name = "data-volume"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mongo_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mongo" {
  metadata {
    name      = "mongo-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.mongo.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.mongo_port
      target_port = local.mongo_port
    }
    type = "NodePort"
  }
}
