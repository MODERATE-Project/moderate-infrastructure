locals {
  ui_app_name     = "ui-app"
  ui_port         = 80
  ui_service_name = "ui-service"
}

resource "kubernetes_deployment" "moderate_ui" {
  metadata {
    name      = "ui-deployment"
    namespace = local.namespace
    labels = {
      app = local.ui_app_name
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.ui_app_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.ui_app_name
        }
      }
      spec {
        container {
          image             = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/moderate-ui:${local.image_tag}"
          name              = "ui"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = local.ui_port
          }
          env {
            name  = "MODERATE_API_URL"
            value = "http://${local.service_name}.${local.namespace}.svc.cluster.local:${local.api_port}"
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
          readiness_probe {
            http_get {
              path = "/"
              port = local.ui_port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          liveness_probe {
            http_get {
              path = "/"
              port = local.ui_port
            }
            initial_delay_seconds = 10
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

resource "kubernetes_service" "moderate_ui" {
  metadata {
    name      = local.ui_service_name
    namespace = local.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.moderate_ui.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.ui_port
      target_port = local.ui_port
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "moderate_ui" {
  metadata {
    name      = "ui-ingress"
    namespace = local.namespace

    annotations = {
      "kubernetes.io/ingress.class"                 = "nginx"
      "cert-manager.io/cluster-issuer"              = var.cert_manager_issuer
      "nginx.ingress.kubernetes.io/proxy-body-size" = var.ui_proxy_body_size
    }
  }

  spec {
    tls {
      secret_name = "ui-ingress-tls-secret"
      hosts       = [var.domain_ui]
    }

    rule {
      host = var.domain_ui

      http {
        path {
          backend {
            service {
              name = kubernetes_service.moderate_ui.metadata[0].name
              port {
                number = local.ui_port
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
