# https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to
# https://cert-manager.io/docs/configuration/acme/dns01/google/#gke-workload-identity

resource "kubernetes_service_account" "ksa_dns_solver" {
  metadata {
    name      = "ksa-dns01-solver"
    namespace = kubernetes_namespace.cert_manager.id
  }
}

locals {
  ksa_dns_name      = kubernetes_service_account.ksa_dns_solver.metadata[0].name
  ksa_dns_namespace = kubernetes_service_account.ksa_dns_solver.metadata[0].namespace
}

resource "google_service_account" "gsa_dns_solver" {
  account_id   = "gsa-dns01-solver"
  display_name = "Service account for the Google CloudDNS cert-manager solver"
  project      = var.gke_cluster_project_id
}

resource "google_project_iam_binding" "gsa_dns_solver_project_iam_binding" {
  project = var.cloud_dns_project_id
  role    = "roles/dns.admin"

  members = [
    "serviceAccount:${google_service_account.gsa_dns_solver.email}"
  ]
}

resource "google_service_account_iam_binding" "gsa_iam_binding_dns_solver" {
  service_account_id = google_service_account.gsa_dns_solver.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gke_cluster_project_id}.svc.id.goog[${local.ksa_dns_namespace}/${local.ksa_dns_name}]"
  ]
}

resource "kubernetes_annotations" "ksa_gsa_annotation_dns_solver" {
  api_version = "v1"
  kind        = "ServiceAccount"

  metadata {
    name      = local.ksa_dns_name
    namespace = local.ksa_dns_namespace
  }

  annotations = {
    "iam.gke.io/gcp-service-account" = google_service_account.gsa_dns_solver.email
  }
}
