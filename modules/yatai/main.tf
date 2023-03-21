resource "kubernetes_namespace" "yatai" {
  count = var.namespace == null ? 1 : 0
  metadata {
    annotations = { name = "yatai" }
    name        = "yatai"
  }
}

locals {
  namespace = var.namespace == null ? one(kubernetes_namespace.yatai[*].id) : var.namespace
}

resource "google_service_account" "bucket_admin_sa" {
  account_id = "bucket-admin-sa"
  project    = var.project_id
}

resource "google_project_iam_binding" "iam_binding_object_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  members = ["serviceAccount:${google_service_account.bucket_admin_sa.email}"]
}

module "bucket" {
  source          = "terraform-google-modules/cloud-storage/google"
  version         = "~> 3.4"
  project_id      = var.project_id
  location        = var.region
  force_destroy   = { "yatai" = true }
  prefix          = "moderate"
  names           = ["yatai"]
  admins          = ["serviceAccount:${google_service_account.bucket_admin_sa.email}"]
  set_admin_roles = true
}

resource "google_storage_hmac_key" "bucket_hmac_key" {
  service_account_email = google_service_account.bucket_admin_sa.email
  project               = var.project_id
}

resource "random_password" "password" {
  length = 20
}

resource "google_sql_user" "sql_user" {
  instance        = var.google_sql_database_instance_name
  name            = "yatai"
  password        = random_password.password.result
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "sql_database" {
  instance = var.google_sql_database_instance_name
  name     = "yatai"
}

locals {
  yatai_wait_duration = "20s"
}

resource "helm_release" "yatai_deployment_crds" {
  name       = "yatai-deployment-crds"
  repository = "https://bentoml.github.io/helm-charts"
  chart      = "yatai-deployment-crds"
  version    = "1.1.7"
  namespace  = local.namespace
}

resource "time_sleep" "wait_yatai_deployment_crds" {
  depends_on      = [helm_release.yatai_deployment_crds]
  create_duration = local.yatai_wait_duration
}

locals {
  yatai_deployment_config = {
    "layers" = {
      "network" = {
        "ingressClass" = "nginx"
        "ingressAnnotations" : {
          "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
        }
      }
    }
    "yataiSystem" = {
      "namespace" = local.namespace
    }
  }
}

resource "helm_release" "yatai_deployment" {
  depends_on = [time_sleep.wait_yatai_deployment_crds]
  name       = "yatai-deployment"
  repository = "https://bentoml.github.io/helm-charts"
  chart      = "yatai-deployment"
  version    = "1.1.7"
  namespace  = local.namespace
  values     = [yamlencode(local.yatai_deployment_config)]
}

resource "time_sleep" "wait_yatai_deployment" {
  depends_on      = [helm_release.yatai_deployment]
  create_duration = local.yatai_wait_duration
}

locals {
  yatai_config = {
    "postgresql" = {
      "host"     = var.postgres_host
      "port"     = var.postgres_port
      "user"     = google_sql_user.sql_user.name
      "database" = google_sql_database.sql_database.name
      "password" = google_sql_user.sql_user.password
      "sslmode"  = "disable"
    }
    "s3" = {
      "endpoint"   = "https://storage.googleapis.com"
      "region"     = "auto"
      "bucketName" = module.bucket.name
      "secure"     = true
      "accessKey"  = google_storage_hmac_key.bucket_hmac_key.access_id
      "secretKey"  = google_storage_hmac_key.bucket_hmac_key.secret
    }
    "ingress" = {
      "enabled"   = true
      "className" = "nginx"
      "annotations" = {
        "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
      }
      "tls" = [{
        "secretName" = "yatai-ingress-tls-secret"
        "hosts"      = [var.domain]
      }]
      "hosts" = [{
        "host"  = var.domain
        "paths" = ["/"]
      }]
    }
  }
}

resource "helm_release" "yatai" {
  depends_on = [time_sleep.wait_yatai_deployment]
  name       = "yatai"
  repository = "https://bentoml.github.io/helm-charts"
  chart      = "yatai"
  version    = "1.1.7"
  namespace  = local.namespace
  values     = [yamlencode(local.yatai_config)]
}
