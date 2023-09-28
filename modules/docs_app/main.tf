resource "kubernetes_namespace" "docs" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "docs" }
    name        = "docs"
  }
}

locals {
  app_name  = "docs-app"
  namespace = var.namespace == null ? one(kubernetes_namespace.docs[*].id) : var.namespace
}

resource "kubernetes_deployment" "docs" {
  metadata {
    name      = "docs-deployment"
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
          image             = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/moderate-docs:latest"
          name              = "docs"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 20
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 20
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 6
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "docs" {
  metadata {
    name      = "docs-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.docs.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 8080
      target_port = 80
    }
    type = "NodePort"
  }
}


resource "kubernetes_ingress_v1" "docs" {
  metadata {
    name      = "docs-ingress"
    namespace = local.namespace

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
    }
  }

  spec {
    tls {
      secret_name = "docs-ingress-tls-secret"
      hosts       = [var.domain]
    }

    rule {
      host = var.domain

      http {
        path {
          backend {
            service {
              name = kubernetes_service.docs.metadata[0].name
              port {
                number = 8080
              }
            }
          }

          path      = "/"
          path_type = "Prefix"
        }
      }
    }
  }
}
