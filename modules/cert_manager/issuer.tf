locals {
  issuer_staging        = "letsencrypt-staging"
  issuer_prod           = "letsencrypt-prod"
  issuer_secret_staging = "letsencrypt-staging"
  issuer_secret_prod    = "letsencrypt-prod"
}

resource "google_service_account" "cm_dns_sa" {
  count        = var.use_dns01_google_cloud_dns ? 1 : 0
  account_id   = "cert-manager-cloud-dns"
  display_name = "Service account used by cert-manager to access Cloud DNS"
}

resource "google_project_iam_member" "cm_dns_iam" {
  count   = var.use_dns01_google_cloud_dns ? 1 : 0
  project = var.project_id_cloud_dns
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.cm_dns_sa[0].email}"
}

resource "google_service_account_key" "cm_dns_sa_key" {
  count              = var.use_dns01_google_cloud_dns ? 1 : 0
  service_account_id = google_service_account.cm_dns_sa[0].name
}

resource "kubernetes_secret" "cm_dns_secret" {
  count = var.use_dns01_google_cloud_dns ? 1 : 0

  metadata {
    name      = "clouddns-dns01-solver-svc-acct"
    namespace = kubernetes_namespace.cert_manager.id
  }

  data = {
    "key.json" = base64decode(google_service_account_key.cm_dns_sa_key[0].private_key)
  }
}

# Annotation cluster-autoscaler.kubernetes.io/safe-to-evict is required due to GKE autoscaler issues:
# https://github.com/cert-manager/cert-manager/issues/5267

locals {
  solver_dns = var.use_dns01_google_cloud_dns ? {
    "dns01" = {
      "cloudDNS" = {
        "project" = var.project_id_cloud_dns
        "serviceAccountSecretRef" = {
          "name" = kubernetes_secret.cm_dns_secret[0].metadata[0].name
          "key"  = "key.json"
        }
      }
    }
  } : null

  solver_http = {
    "http01" = {
      "ingress" = {
        "class" = "nginx"
        "podTemplate" = {
          "metadata" = {
            "annotations" = {
              "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
            }
          }
        }
      }
    }
  }
}

# Hack to avoid "Inconsistent conditional result types":
# https://github.com/hashicorp/terraform/issues/22405

locals {
  solver_hack = {
    true  = local.solver_dns
    false = local.solver_http
  }
}

resource "kubectl_manifest" "letsencrypt_staging_issuer" {
  depends_on = [time_sleep.wait_after_helm_cert_manager]
  wait       = true

  yaml_body = yamlencode({
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name"      = local.issuer_staging
      "namespace" = kubernetes_namespace.cert_manager.id
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
        "email"  = var.cluster_admin_account
        "privateKeySecretRef" = {
          "name" = local.issuer_secret_staging
        }
        "solvers" = [local.solver_hack[var.use_dns01_google_cloud_dns]]
      }
    }
  })
}

resource "kubectl_manifest" "letsencrypt_prod_issuer" {
  depends_on = [time_sleep.wait_after_helm_cert_manager]
  wait       = true

  yaml_body = yamlencode({
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name"      = local.issuer_prod
      "namespace" = kubernetes_namespace.cert_manager.id
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "email"  = var.cluster_admin_account
        "privateKeySecretRef" = {
          "name" = local.issuer_secret_prod
        }
        "solvers" = [local.solver_hack[var.use_dns01_google_cloud_dns]]
      }
    }
  })
}
