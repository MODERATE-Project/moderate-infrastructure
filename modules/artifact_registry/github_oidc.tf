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

# Workload Identity Pool names cannot be reused, so we generate a random suffix
# https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers#delete-provider
resource "random_string" "workload_identity_pool_suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  numeric = false
}

module "gh_oidc" {
  source      = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  project_id  = var.project_id
  pool_id     = "gh-artifact-reg-pool-${random_string.workload_identity_pool_suffix.result}"
  provider_id = "gh-arfifact-registry-provider"
  sa_mapping = {
    (google_service_account.sa.account_id) = {
      sa_name   = google_service_account.sa.name
      attribute = "*"
    }
  }
}
