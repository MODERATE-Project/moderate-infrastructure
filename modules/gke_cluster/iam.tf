data "google_compute_default_service_account" "default" {}

# Grant permissions for Artifact Registries in different projects
# https://cloud.google.com/artifact-registry/docs/access-control#grant

resource "google_project_iam_binding" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${data.google_compute_default_service_account.default.email}",
  ]
}
