resource "kubernetes_namespace" "cloud_sql" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "cloudsql" }
    name        = "cloudsql"
  }
}

locals {
  proxy_app     = "cloud-sql-proxy"
  postgres_port = 5432
  namespace     = var.namespace == null ? one(kubernetes_namespace.cloud_sql[*].id) : var.namespace
}

module "cloud_sql_proxy_wi" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version    = "~> 36.1.0"
  name       = "cloud-sql-proxy"
  namespace  = local.namespace
  project_id = var.project_id
  roles      = ["roles/cloudsql.client"]
}

resource "kubernetes_deployment" "cloud_sql" {
  metadata {
    name      = "cloud-sql-deployment"
    namespace = local.namespace
    labels = {
      app = local.proxy_app
    }
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = local.proxy_app
      }
    }
    template {
      metadata {
        labels = {
          app = local.proxy_app
        }
      }
      spec {
        service_account_name = module.cloud_sql_proxy_wi.k8s_service_account_name
        node_selector = {
          "iam.gke.io/gke-metadata-server-enabled" : true
        }
        container {
          image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.1.1"
          name  = "cloud-sql-proxy"
          args = [
            "--private-ip",
            "--structured-logs",
            "--port=${local.postgres_port}",
            "--address=0.0.0.0",
            "${var.cloud_sql_connection_name}"
          ]
          security_context {
            run_as_non_root = true
          }
          port {
            container_port = local.postgres_port
          }
          resources {
            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "cloud_sql" {
  metadata {
    name      = "cloud-sql-service"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = local.proxy_app
    }
    port {
      port        = local.postgres_port
      target_port = local.postgres_port
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_service" "cloud_sql_internal_service" {
  metadata {
    name      = "cloud-sql-internal-service"
    namespace = local.namespace
    annotations = {
      "cloud.google.com/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = local.proxy_app
    }
    port {
      port        = local.postgres_port
      target_port = local.postgres_port
    }
    type = "LoadBalancer"
  }
}
