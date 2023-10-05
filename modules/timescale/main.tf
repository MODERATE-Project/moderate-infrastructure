resource "kubernetes_namespace" "timescale" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "timescale" }
    name        = "timescale"
  }
}

locals {
  app_name  = "timescale-app"
  namespace = var.namespace == null ? one(kubernetes_namespace.timescale[*].id) : var.namespace
  pg_port   = 5432
}

resource "random_password" "timescale_postgres_password" {
  length  = 24
  special = false
}

resource "kubernetes_persistent_volume_claim" "timescale_pvc" {
  metadata {
    name      = "timescale-pvc"
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

# ToDo: Update configuration in accordance with the machine's resources.
# https://docs.timescale.com/self-hosted/latest/configuration/about-configuration/
resource "kubernetes_deployment" "timescale" {
  metadata {
    name      = "timescale-deployment"
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
          # The "-ha" indicates that it includes the Patroni HA controller.
          # The lack of "-oss" indicates that this is the Community version:
          # https://docs.timescale.com/about/latest/timescaledb-editions/
          image = "timescale/timescaledb-ha:pg14.9-ts2.11.2-all"
          name  = "timescale"
          port {
            container_port = local.pg_port
          }
          volume_mount {
            name = "data-volume"
            # https://docs.timescale.com/self-hosted/latest/install/installation-docker/
            mount_path = "/home/postgresql/pgdata"
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.timescale_postgres_password.result
          }
          env {
            name  = "POSTGRES_DB"
            value = var.default_db
          }
        }
        volume {
          name = "data-volume"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.timescale_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "timescale" {
  metadata {
    name      = "timescale-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.timescale.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = local.pg_port
      target_port = local.pg_port
    }
    type = "ClusterIP"
  }
}
