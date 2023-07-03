locals {
  ts_app_name  = "ts-grafana-app"
  grafana_port = 3000
}

resource "random_password" "ts_grafana_admin_password" {
  count   = var.grafana_enable ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "ts_grafana_secret_key" {
  count   = var.grafana_enable ? 1 : 0
  length  = 32
  special = false
}

resource "kubernetes_persistent_volume_claim" "ts_grafana_pvc" {
  count = var.grafana_enable ? 1 : 0

  metadata {
    name      = "ts-grafana-pvc"
    namespace = local.namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_secret" "ts_grafana_secrets" {
  count = var.grafana_enable ? 1 : 0

  metadata {
    name      = "ts-grafana-secrets"
    namespace = local.namespace
  }

  data = {
    GF_SECURITY_ADMIN_PASSWORD = random_password.ts_grafana_admin_password[0].result
    GF_SECURITY_SECRET_KEY     = random_password.ts_grafana_secret_key[0].result
  }
}

resource "kubernetes_deployment" "ts_grafana" {
  count = var.grafana_enable ? 1 : 0

  metadata {
    name      = "ts-grafana-deployment"
    namespace = local.namespace
    labels = {
      app = local.ts_app_name
    }
  }

  spec {
    selector {
      match_labels = {
        app = local.ts_app_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.ts_app_name
        }
      }
      spec {
        security_context {
          run_as_user = 0
        }
        container {
          image = "grafana/grafana:10.0.1-ubuntu"
          name  = "grafana"
          port {
            container_port = local.grafana_port
          }
          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.ts_grafana_secrets[0].metadata[0].name
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
          env {
            name  = "GF_SECURITY_ADMIN_USER"
            value = var.grafana_admin_user
          }
        }
        volume {
          name = "grafana-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ts_grafana_pvc[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ts_grafana" {
  count = var.grafana_enable ? 1 : 0

  metadata {
    name      = "ts-grafana-service"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.ts_grafana[0].spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.grafana_port
      target_port = local.grafana_port
    }
    type = "NodePort"
  }
}


resource "kubernetes_ingress_v1" "ts_grafana" {
  count = var.grafana_enable ? 1 : 0

  metadata {
    name      = "ts-grafana-ingress"
    namespace = local.namespace

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = var.grafana_cert_manager_issuer
    }
  }

  spec {
    tls {
      secret_name = "ts-grafana-ingress-tls-secret"
      hosts       = [var.grafana_domain]
    }

    rule {
      host = var.grafana_domain

      http {
        path {
          backend {
            service {
              name = kubernetes_service.ts_grafana[0].metadata[0].name
              port {
                number = local.grafana_port
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
