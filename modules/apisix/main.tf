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

    "apisix.yaml" = templatefile("${path.module}/apisix.yaml.tftpl", {})
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
