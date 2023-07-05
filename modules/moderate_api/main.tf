resource "kubernetes_namespace" "moderate_api" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "moderate-api" }
    name        = "api"
  }
}

locals {
  app_name     = "api-app"
  namespace    = var.namespace == null ? one(kubernetes_namespace.moderate_api[*].id) : var.namespace
  api_port     = 8000
  service_name = "api-service"
}

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
        container {
          image = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/moderate-api:latest"
          name  = "api"
          port {
            container_port = local.api_port
          }
          resources {
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
    type = "NodePort"
  }
}
