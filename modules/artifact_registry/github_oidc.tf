# These resources are required to configure Workload Identity Federation 
# to enable GitHub Actions to push images to Artifact Registry:
# https://github.com/terraform-google-modules/terraform-google-github-actions-runners/tree/v3.1.1/modules/gh-oidc

resource "google_service_account" "sa" {
  project    = var.project_id
  account_id = "artifact-registry-ghactions-sa"
}

resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

module "gh_oidc" {
  source      = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  project_id  = var.project_id
  pool_id     = "gh-artifact-registry-pool"
  provider_id = "gh-arfifact-registry-provider"
  sa_mapping = {
    (google_service_account.sa.account_id) = {
      sa_name   = google_service_account.sa.name
      attribute = "*"
    }
  }
}
