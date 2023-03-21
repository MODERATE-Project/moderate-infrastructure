resource "google_service_account" "sa_artifact_registry" {
  account_id   = "artifact-registry-static-sa"
  display_name = "Service account to provide a static key for access to Artifact Registry"
}

resource "google_service_account_key" "sa_artifact_registry_key" {
  service_account_id = google_service_account.sa_artifact_registry.name
}

resource "google_project_iam_member" "sa_artifact_registry_role" {
  project = var.project_id
  role    = "roles/artifactregistry.repoAdmin"
  member  = "serviceAccount:${google_service_account.sa_artifact_registry.email}"
}
