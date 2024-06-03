resource "kubernetes_namespace" "geoserver" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "geoserver" }
    name        = "geoserver"
  }
}

locals {
  app_name       = "geoserver-app"
  geoserver_port = 8080
  vol_name       = "geoserver-data"
  namespace      = var.namespace == null ? one(kubernetes_namespace.geoserver[*].id) : var.namespace
}

resource "kubernetes_persistent_volume_claim" "geoserver_pvc" {
  metadata {
    name      = "geoserver-pvc"
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

resource "random_password" "geoserver_admin_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "geoserver_secrets" {
  metadata {
    name      = "geoserver-secrets"
    namespace = local.namespace
  }

  data = {
    GEOSERVER_ADMIN_PASSWORD = random_password.geoserver_admin_password.result
  }
}

locals {
  image_tag = "eddbe1ae6de875d4748d212c420302fa13c8d5c5"
}

// trunk-ignore(checkov/CKV_K8S_8)
// trunk-ignore(checkov/CKV_K8S_9)
// trunk-ignore(checkov/CKV_K8S_35): Prefer using secrets as files over secrets as environment variables
resource "kubernetes_deployment" "geoserver" {
  metadata {
    name      = "geoserver-deployment"
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
          image             = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/moderate-geoserver:${local.image_tag}"
          name              = "geoserver"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = local.geoserver_port
          }
          volume_mount {
            name       = local.vol_name
            mount_path = "/opt/geoserver/data_dir"
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }
          # https://github.com/kartoza/docker-geoserver/blob/ffecc3cedf0de65b87d23c92e06b96214e07c6b2/.env
          env_from {
            secret_ref {
              name = kubernetes_secret.geoserver_secrets.metadata[0].name
            }
          }
          env {
            name  = "GEOSERVER_DATA_DIR"
            value = "/opt/geoserver/data_dir"
          }
          env {
            name  = "GEOWEBCACHE_CACHE_DIR"
            value = "/opt/geoserver/data_dir/gwc"
          }
          env {
            name  = "GEOSERVER_ADMIN_USER"
            value = "admin"
          }
          env {
            name  = "INITIAL_MEMORY"
            value = "1G"
          }
          env {
            name  = "MAXIMUM_MEMORY"
            value = "4G"
          }
          env {
            name  = "STABLE_EXTENSIONS"
            value = var.stable_extensions
          }
          env {
            name  = "COMMUNITY_EXTENSIONS"
            value = var.community_extensions
          }
          env {
            name  = "TOMCAT_EXTRAS"
            value = false
          }
          env {
            name  = "ROOT_WEBAPP_REDIRECT"
            value = true
          }
          # https://github.com/kartoza/docker-geoserver/issues/293#issuecomment-1235755773
          env {
            name  = "HTTP_SCHEME"
            value = "https"
          }
          env {
            name  = "HTTP_PROXY_NAME"
            value = var.domain
          }
        }
        volume {
          name = local.vol_name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.geoserver_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "geoserver" {
  metadata {
    name      = "geoserver-service"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.geoserver.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.geoserver_port
      target_port = local.geoserver_port
    }
    type = "NodePort"
  }
}


resource "kubernetes_ingress_v1" "geoserver" {
  metadata {
    name      = "geoserver-ingress"
    namespace = local.namespace

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
    }
  }

  spec {
    tls {
      secret_name = "geoserver-ingress-tls-secret"
      hosts       = [var.domain]
    }

    rule {
      host = var.domain

      http {
        path {
          backend {
            service {
              name = kubernetes_service.geoserver.metadata[0].name
              port {
                number = local.geoserver_port
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
