resource "kubernetes_persistent_volume_claim" "elastic_pvc" {
  metadata {
    name      = "elastic-pvc"
    namespace = local.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.elastic_volume_size_gi}Gi"
      }
    }
  }
  wait_until_bound = false
}

locals {
  app_name               = "elasticsearch-app"
  elastic_port_http      = 9200
  data_volume            = "data-volume"
  data_volume_mount_path = "/usr/share/elasticsearch/data"
}

resource "kubernetes_deployment" "elastic" {
  metadata {
    name      = "elastic-deployment"
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
        # https://github.com/elastic/helm-charts/issues/258
        init_container {
          name  = "file-permissions"
          image = "busybox"
          command = [
            "chown",
            "-R",
            "1000:1000",
            "/usr/share/elasticsearch/"
          ]
          volume_mount {
            name       = local.data_volume
            mount_path = local.data_volume_mount_path
          }
          security_context {
            privileged  = true
            run_as_user = 0
          }
        }
        container {
          image             = "docker.elastic.co/elasticsearch/elasticsearch:7.17.13"
          name              = "elasticsearch"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          port {
            container_port = local.elastic_port_http
          }
          volume_mount {
            name       = local.data_volume
            mount_path = local.data_volume_mount_path
          }
          resources {
            requests = {
              cpu    = "150m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }
          env {
            name  = "discovery.type"
            value = "single-node"
          }
          readiness_probe {
            http_get {
              path = "/_cluster/health"
              port = local.elastic_port_http
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 3
          }
          liveness_probe {
            http_get {
              path = "/_cluster/health"
              port = local.elastic_port_http
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 6
          }
        }
        volume {
          name = local.data_volume
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.elastic_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "elastic" {
  metadata {
    name      = "elastic-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.elastic.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.elastic_port_http
      target_port = local.elastic_port_http
    }
    type = "ClusterIP"
  }
}
