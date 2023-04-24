locals {
  nginx_name         = "nginx-yatai-router"
  vol_config         = "config"
  bento_service_port = 3000
}

resource "kubernetes_config_map" "nginx" {
  metadata {
    name      = local.nginx_name
    namespace = local.namespace
  }

  data = {
    "default.conf" = templatefile("${path.module}/nginx.conf.tftpl", {
      yatai_ns              = local.namespace
      yatai_deployment_port = local.bento_service_port
    })
  }
}

resource "kubernetes_deployment" "nginx" {
  lifecycle {
    replace_triggered_by = [
      kubernetes_config_map.nginx.data
    ]
  }
  metadata {
    name      = local.nginx_name
    namespace = local.namespace
    labels = {
      app = local.nginx_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.nginx_name
      }
    }
    template {
      metadata {
        labels = {
          app = local.nginx_name
        }
      }
      spec {
        container {
          image = "nginx:1.23"
          name  = "nginx"
          port {
            container_port = 80
          }
          resources {
            limits = {
              cpu    = "1000m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
          volume_mount {
            name       = local.vol_config
            mount_path = "/etc/nginx/conf.d/default.conf"
            sub_path   = "default.conf"
          }
        }
        volume {
          name = local.vol_config
          config_map {
            name = one(kubernetes_config_map.nginx.metadata[*].name)
            items {
              key  = "default.conf"
              path = "default.conf"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = local.nginx_name
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.nginx.spec.0.template.0.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}
