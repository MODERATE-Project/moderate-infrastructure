resource "kubernetes_namespace" "docs" {
  metadata {
    annotations = {
      name = "docs"
    }
    name = "docs"
  }
}

locals {
  docs_app_name = "docs-app"
}

resource "kubernetes_deployment" "docs" {
  metadata {
    name      = "docs-deployment"
    namespace = kubernetes_namespace.docs.metadata[0].name
    labels = {
      app = local.docs_app_name
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = local.docs_app_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.docs_app_name
        }
      }
      spec {
        container {
          image = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/moderate-docs:latest"
          name  = "docs"
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu    = "150m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "docs" {
  metadata {
    name      = "docs-service"
    namespace = kubernetes_namespace.docs.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.docs.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 8080
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

