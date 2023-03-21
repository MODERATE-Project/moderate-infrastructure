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
  ingress_config = {
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
  name       = "yatai"
  repository = "https://bentoml.github.io/helm-charts"
  chart      = "yatai"
  version    = "1.1.7"
  namespace  = local.namespace

  set {
    name  = "postgresql.host"
    value = var.postgres_host
  }

  set {
    name  = "postgresql.port"
    value = var.postgres_port
  }

  set {
    name  = "postgresql.user"
    value = google_sql_user.sql_user.name
  }

  set {
    name  = "postgresql.database"
    value = google_sql_database.sql_database.name
  }

  set {
    name  = "postgresql.password"
    value = google_sql_user.sql_user.password
  }

  set {
    name  = "postgresql.sslmode"
    value = "disable"
  }

  set {
    name  = "s3.endpoint"
    value = "https://storage.googleapis.com"
  }

  set {
    name  = "s3.region"
    value = "auto"
  }

  set {
    name  = "s3.bucketName"
    value = module.bucket.name
  }

  set {
    name  = "s3.secure"
    value = true
  }

  set {
    name  = "s3.accessKey"
    value = google_storage_hmac_key.bucket_hmac_key.access_id
  }

  set {
    name  = "s3.secretKey"
    value = google_storage_hmac_key.bucket_hmac_key.secret
  }

  values = [yamlencode(local.ingress_config)]
}
