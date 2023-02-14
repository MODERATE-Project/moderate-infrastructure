resource "google_artifact_registry_repository" "image_repository" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
}
