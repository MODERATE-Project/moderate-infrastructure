resource "google_service_account" "api_bucket_admin_sa" {
  account_id = "api-bucket-admin-sa"
  project    = var.project_id
}

locals {
  prefix              = "moderate"
  api_bucket_name     = "platform-api"
  outputs_bucket_name = "outputs"
}

module "bucket" {
  source                   = "terraform-google-modules/cloud-storage/google"
  version                  = "~> 9.1.0"
  project_id               = var.project_id
  location                 = var.region
  public_access_prevention = "enforced"
  prefix                   = local.prefix
  names                    = [local.api_bucket_name, local.outputs_bucket_name]
  force_destroy            = { (local.api_bucket_name) = true, (local.outputs_bucket_name) = true }
  storage_admins           = ["serviceAccount:${google_service_account.api_bucket_admin_sa.email}"]
  set_storage_admin_roles  = true
}

resource "google_storage_hmac_key" "api_bucket_hmac_key" {
  service_account_email = google_service_account.api_bucket_admin_sa.email
  project               = var.project_id
}
