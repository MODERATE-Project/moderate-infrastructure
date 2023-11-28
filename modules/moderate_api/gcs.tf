resource "google_service_account" "api_bucket_admin_sa" {
  account_id = "api-bucket-admin-sa"
  project    = var.project_id
}

locals {
  api_bucket_name = "platformapi"
}

module "bucket" {
  source                   = "terraform-google-modules/cloud-storage/google"
  version                  = "~> 5.0"
  project_id               = var.project_id
  location                 = var.region
  public_access_prevention = "enforced"
  prefix                   = "moderate"
  names                    = [local.api_bucket_name]
  force_destroy            = { (local.api_bucket_name) = true }
  storage_admins           = ["serviceAccount:${google_service_account.api_bucket_admin_sa.email}"]
  set_storage_admin_roles  = true
}

resource "google_storage_hmac_key" "api_bucket_hmac_key" {
  service_account_email = google_service_account.api_bucket_admin_sa.email
  project               = var.project_id
}
