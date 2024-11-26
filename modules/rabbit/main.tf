resource "kubernetes_namespace" "rabbit" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "rabbit" }
    name        = "rabbit"
  }
}

locals {
  app_name               = "rabbit-app"
  namespace              = var.namespace == null ? one(kubernetes_namespace.rabbit[*].id) : var.namespace
  rabbit_user            = "rabbit"
  rabbit_port            = 5672
  rabbit_management_port = 15672
}

resource "random_password" "rabbit_admin_password" {
  length  = 24
  special = false
}

resource "kubernetes_deployment" "rabbit" {
  metadata {
    name      = "rabbit-deployment"
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
          image             = "rabbitmq:4-management"
          name              = "rabbit"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = local.rabbit_port
          }
          port {
            container_port = local.rabbit_management_port
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2048Mi"
            }
          }
          env {
            name  = "RABBITMQ_DEFAULT_USER"
            value = local.rabbit_user
          }
          env {
            name  = "RABBITMQ_DEFAULT_PASS"
            value = random_password.rabbit_admin_password.result
          }
          liveness_probe {
            exec {
              command = ["rabbitmq-diagnostics", "-q", "ping"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = ["rabbitmq-diagnostics", "-q", "ping"]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "rabbit" {
  metadata {
    name      = "rabbit-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.rabbit.spec[0].template[0].metadata[0].labels.app
    }
    port {
      name        = "rabbit-port"
      port        = local.rabbit_port
      target_port = local.rabbit_port
    }
    port {
      name        = "rabbit-management-port"
      port        = local.rabbit_management_port
      target_port = local.rabbit_management_port
    }
    type = "NodePort"
  }
}
