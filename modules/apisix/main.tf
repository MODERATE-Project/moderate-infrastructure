resource "kubernetes_namespace" "apisix" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "apisix" }
    name        = "apisix"
  }
}

locals {
  namespace                     = var.namespace == null ? one(kubernetes_namespace.apisix[*].id) : var.namespace
  apisix_node_listen            = 9080
  apisix_control_port           = 9092
  apisix_prometheus_export_port = 9091
}

resource "random_password" "admin_key" {
  length  = 32
  special = false
}

resource "random_password" "docs_basic_auth_password" {
  length  = 20
  special = false
}

locals {
  domain_base  = "${var.base_subdomain}.${var.base_domain}"
  domain_docs  = "${var.docs_subdomain}.${local.domain_base}"
  domain_yatai = "*.${var.yatai_subdomain}.${local.domain_base}"

  all_domains = [
    local.domain_base,
    local.domain_docs,
    local.domain_yatai
  ]
}

# ToDo: This should be a Secret instead of a ConfigMap
resource "kubernetes_config_map" "apisix" {
  metadata {
    name      = "apisix-config"
    namespace = local.namespace
  }

  data = {
    "config.yaml" = templatefile("${path.module}/config.yaml.tftpl", {
      apisix_node_listen            = local.apisix_node_listen
      apisix_control_port           = local.apisix_control_port
      apisix_admin_key              = random_password.admin_key.result
      apisix_prometheus_export_port = local.apisix_prometheus_export_port
    })

    "apisix.yaml" = templatefile("${path.module}/apisix.yaml.tftpl", {
      docs_basic_auth_password   = random_password.docs_basic_auth_password.result
      host_docs                  = local.domain_docs
      host_yatai                 = local.domain_yatai
      yatai_ns                   = var.yatai_namespace
      yatai_proxy_sv             = var.yatai_proxy_service
      base_domain                = var.base_domain
      keycloak_subdomain         = var.keycloak_subdomain
      keycloak_realm             = var.keycloak_realm
      keycloak_client_id         = var.keycloak_client_id
      keycloak_client_secret     = var.keycloak_client_secret
      keycloak_permissions_yatai = var.keycloak_permissions_yatai
    })
  }
}

locals {
  app_name            = "apisix"
  vol_config_readonly = "config-readonly"
  vol_config          = "config"
  apisix_tag          = "3.2.0-debian"
  config_yaml         = "config.yaml"
  apisix_yaml         = "apisix.yaml"
}

resource "kubernetes_deployment" "apisix" {
  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.apisix.data
    ]
  }
  metadata {
    name      = "apisix-deployment"
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
          image = "apache/apisix:${local.apisix_tag}"
          name  = "apisix"
          port {
            container_port = local.apisix_node_listen
          }
          port {
            container_port = local.apisix_control_port
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
          volume_mount {
            name       = local.vol_config
            mount_path = "/usr/local/apisix/conf/${local.config_yaml}"
            sub_path   = local.config_yaml
          }
          volume_mount {
            name       = local.vol_config
            mount_path = "/usr/local/apisix/conf/${local.apisix_yaml}"
            sub_path   = local.apisix_yaml
          }
        }
        init_container {
          image   = "apache/apisix:${local.apisix_tag}"
          name    = "copy-config"
          command = ["sh", "-c", "/bin/cp /var/config/* /var/config-writable/"]
          volume_mount {
            name       = local.vol_config_readonly
            mount_path = "/var/config"
          }
          volume_mount {
            name       = local.vol_config
            mount_path = "/var/config-writable"
          }
        }
        volume {
          name = local.vol_config_readonly
          config_map {
            name         = one(kubernetes_config_map.apisix.metadata[*].name)
            default_mode = "0777"
            items {
              key  = local.config_yaml
              path = local.config_yaml
            }
            items {
              key  = local.apisix_yaml
              path = local.apisix_yaml
            }
          }
        }
        volume {
          name = local.vol_config
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "apisix" {
  metadata {
    name      = "apisix-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.apisix.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.apisix_node_listen
      target_port = local.apisix_node_listen
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "apisix" {
  metadata {
    name      = "apisix-ingress"
    namespace = local.namespace

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
    }
  }

  spec {
    tls {
      secret_name = "apisix-ingress-tls-secret"
      hosts       = local.all_domains
    }

    dynamic "rule" {
      for_each = local.all_domains

      content {
        host = rule.value

        http {
          path {
            backend {
              service {
                name = one(kubernetes_service.apisix.metadata[*].name)
                port {
                  number = local.apisix_node_listen
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
}
