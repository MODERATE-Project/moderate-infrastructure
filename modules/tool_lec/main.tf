resource "kubernetes_namespace" "tool_lec" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "tool-lec" }
    name        = "tool-lec"
  }
}

locals {
  app_name            = "tool-lec-app"
  municipalities_name = "tool-lec-municipalities"
  buildings_name      = "tool-lec-buildings"
  namespace           = var.namespace == null ? one(kubernetes_namespace.tool_lec[*].id) : var.namespace
}

// trunk-ignore(checkov/CKV_K8S_8)
// trunk-ignore(checkov/CKV_K8S_9)
resource "kubernetes_deployment" "tool_lec_municipalities" {
  metadata {
    name      = "tool-lec-municipalities-deployment"
    namespace = local.namespace
    labels = {
      app = local.municipalities_name
    }
  }
  spec {
    selector {
      match_labels = {
        app = local.municipalities_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.municipalities_name
        }
      }
      spec {
        container {
          image             = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/tool-lec-municipalities-svc:main"
          name              = "municipalities-svc"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = 5000
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
        }
      }
    }
  }
}

resource "kubernetes_service" "tool_lec_municipalities" {
  metadata {
    name      = "municipalities-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.tool_lec_municipalities.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 5000
      target_port = 5000
    }
    type = "ClusterIP"
  }
}

locals {
  municipalities_svc_name = kubernetes_service.tool_lec_municipalities.metadata[0].name
  municipalities_svc_port = kubernetes_service.tool_lec_municipalities.spec[0].port[0].port
  municipalities_svc_url  = "http://${local.municipalities_svc_name}.${local.namespace}.svc.cluster.local:${local.municipalities_svc_port}"
}

// trunk-ignore(checkov/CKV_K8S_8)
// trunk-ignore(checkov/CKV_K8S_9)
resource "kubernetes_deployment" "tool_lec_buildings" {
  metadata {
    name      = "tool-lec-buildings-deployment"
    namespace = local.namespace
    labels = {
      app = local.buildings_name
    }
  }
  spec {
    selector {
      match_labels = {
        app = local.buildings_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.buildings_name
        }
      }
      spec {
        container {
          image             = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/tool-lec-buildings-svc:main"
          name              = "buildings-svc"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = 5000
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
        }
      }
    }
  }
}

resource "kubernetes_service" "tool_lec_buildings" {
  metadata {
    name      = "buildings-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.tool_lec_buildings.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 5000
      target_port = 5000
    }
    type = "ClusterIP"
  }
}

locals {
  buildings_svc_name = kubernetes_service.tool_lec_buildings.metadata[0].name
  buildings_svc_port = kubernetes_service.tool_lec_buildings.spec[0].port[0].port
  buildings_svc_url  = "http://${local.buildings_svc_name}.${local.namespace}.svc.cluster.local:${local.buildings_svc_port}"
}

resource "kubernetes_config_map" "tool_lec_frontend" {
  metadata {
    name      = "tool-lec-frontend-configmap"
    namespace = local.namespace
  }

  data = {
    MODERATE_GEOSERVER_PROXY_PASS_URL          = var.geoserver_url
    MODERATE_MUNICIPALITIES_SVC_PROXY_PASS_URL = local.municipalities_svc_url
    MODERATE_BUILDINGS_SVC_PROXY_PASS_URL      = local.buildings_svc_url
  }
}

resource "kubernetes_deployment" "tool_lec_frontend" {
  metadata {
    name      = "tool-lec-frontend-deployment"
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
          image             = "europe-west1-docker.pkg.dev/moderate-common/moderate-images/tool-lec-frontend:main"
          name              = "frontend"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = 80
          }
          env_from {
            config_map_ref {
              name = one(kubernetes_config_map.tool_lec_frontend.metadata[*].name)
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
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

resource "kubernetes_service" "tool_lec_frontend" {
  metadata {
    name      = "tool-lec-frontend-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.tool_lec_frontend.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}


resource "kubernetes_ingress_v1" "tool_lec_frontend" {
  metadata {
    name      = "tool-lec-frontend-ingress"
    namespace = local.namespace

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
    }
  }

  spec {
    tls {
      secret_name = "tool-lec-frontend-ingress-tls-secret"
      hosts       = [var.domain]
    }

    rule {
      host = var.domain

      http {
        path {
          backend {
            service {
              name = kubernetes_service.tool_lec_frontend.metadata[0].name
              port {
                number = 80
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
