resource "kubernetes_namespace" "timescale" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "timescale" }
    name        = "timescale"
  }
}

locals {
  app_name  = "timescale-app"
  namespace = var.namespace == null ? one(kubernetes_namespace.timescale[*].id) : var.namespace
}

resource "random_password" "timescale_postgres_password" {
  length  = 24
  special = false
}

resource "kubernetes_deployment" "timescale" {
  metadata {
    name      = "timescale-deployment"
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
          image = "timescaledb:latest-pg14"
          name  = "timescale"
          port {
            container_port = 5432
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.timescale_postgres_password.result
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "timescale" {
  metadata {
    name      = "timescale-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.timescale.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 5432
      target_port = 5432
    }
    type = "NodePort"
  }
}
