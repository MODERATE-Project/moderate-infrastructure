resource "kubernetes_namespace" "keycloak" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "keycloak" }
    name        = "keycloak"
  }
}

locals {
  app_name      = "keycloak-app"
  namespace     = var.namespace == null ? one(kubernetes_namespace.keycloak[*].id) : var.namespace
  postgres_port = 5432
  admin_user    = "admin"
}

resource "random_password" "password_admin_keycloak" {
  length = 20
}

resource "kubernetes_config_map" "keycloak" {
  metadata {
    name      = "keycloak-config"
    namespace = local.namespace
  }

  data = {
    KC_PROXY             = "edge"
    KC_LOG_CONSOLE_COLOR = "true"
    KC_LOG_LEVEL         = "debug"
    KC_HEALTH_ENABLED    = "true"
  }
}

resource "random_password" "password_db" {
  length = 20
}

resource "google_sql_user" "sql_user" {
  instance        = var.cloud_sql_instance_name
  name            = "keycloak"
  password        = random_password.password_db.result
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "sql_database" {
  instance = var.cloud_sql_instance_name
  name     = "keycloak"
}

resource "kubernetes_secret" "keycloak" {
  metadata {
    name      = "keycloak-secrets"
    namespace = local.namespace
  }

  data = {
    KC_DB                   = "postgres"
    KC_DB_USERNAME          = google_sql_user.sql_user.name
    KC_DB_PASSWORD          = google_sql_user.sql_user.password
    KC_DB_URL_PORT          = local.postgres_port
    KC_DB_URL_DATABASE      = google_sql_database.sql_database.name
    KC_DB_URL_HOST          = "localhost"
    KEYCLOAK_ADMIN          = local.admin_user
    KEYCLOAK_ADMIN_PASSWORD = random_password.password_admin_keycloak.result
  }
}

module "cloud_sql_proxy_wi" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "cloud-sql-proxy-keycloak"
  namespace  = local.namespace
  project_id = var.project_id
  roles      = ["roles/cloudsql.client"]
}

resource "kubernetes_deployment" "keycloak" {
  metadata {
    name      = "keycloak-deployment"
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
        service_account_name = module.cloud_sql_proxy_wi.k8s_service_account_name
        container {
          image             = "quay.io/keycloak/keycloak:22.0"
          name              = "keycloak"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          args = [
            "start",
            "--hostname=${var.domain}"
          ]
          env_from {
            config_map_ref {
              name = one(kubernetes_config_map.keycloak.metadata[*].name)
            }
          }
          env_from {
            secret_ref {
              name = one(kubernetes_secret.keycloak.metadata[*].name)
            }
          }
          port {
            container_port = 8080
          }
          resources {
            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/health/live"
              port = 8080
            }
            initial_delay_seconds = 180
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          readiness_probe {
            http_get {
              path = "/health/ready"
              port = 8080
            }
            initial_delay_seconds = 180
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 6
          }
        }
        container {
          image             = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.6"
          name              = "cloudsql-proxy"
          image_pull_policy = "Always"
          security_context {
            allow_privilege_escalation = false
          }
          args = [
            "--private-ip",
            "--structured-logs",
            "--port=${local.postgres_port}",
            "${var.cloud_sql_instance_connection_name}"
          ]
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

locals {
  service_name = "keycloak-service"
  service_port = 9191
}

resource "kubernetes_service" "keycloak" {
  metadata {
    name      = local.service_name
    namespace = local.namespace
  }
  spec {
    selector = {
      app = kubernetes_deployment.keycloak.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = local.service_port
      target_port = 8080
    }
    type = "NodePort"
  }
}


resource "kubernetes_ingress_v1" "keycloak" {
  metadata {
    name      = "keycloak-ingress"
    namespace = local.namespace

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
    }
  }

  spec {
    tls {
      secret_name = "keycloak-ingress-tls-secret"
      hosts       = [var.domain]
    }

    rule {
      host = var.domain

      http {
        path {
          backend {
            service {
              name = kubernetes_service.keycloak.metadata[0].name
              port {
                number = local.service_port
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
