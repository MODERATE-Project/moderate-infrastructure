resource "kubernetes_namespace" "cloud_sql" {
  metadata {
    annotations = { name = "cloudsql" }
    name        = "cloudsql"
  }
}

module "cloud_sql_proxy_wi" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "cloud-sql-proxy"
  namespace  = kubernetes_namespace.cloud_sql.id
  project_id = var.project_id
  roles      = ["roles/cloudsql.client"]
}

locals {
  proxy_app     = "cloud-sql-proxy"
  postgres_port = 5432
}

resource "kubernetes_deployment" "cloud_sql" {
  metadata {
    name      = "cloud-sql-deployment"
    namespace = kubernetes_namespace.cloud_sql.id
    labels = {
      app = local.proxy_app
    }
  }
  spec {
    replicas = 1
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
            "${google_sql_database_instance.postgres_sql_instance.connection_name}"
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
              cpu    = "200m"
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
    namespace = kubernetes_namespace.cloud_sql.id
  }
  spec {
    selector = {
      app = local.proxy_app
    }
    port {
      port        = local.postgres_port
      target_port = local.postgres_port
    }
    type = "NodePort"
  }
}
