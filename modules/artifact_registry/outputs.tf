output "repository_id" {
  value = google_artifact_registry_repository.image_repository.id
}

output "repository_name" {
  value = google_artifact_registry_repository.image_repository.name
}

output "repository_location" {
  value = google_artifact_registry_repository.image_repository.location
}

output "gh_oidc_pool_name" {
  value = module.gh_oidc.pool_name
}

output "gh_oidc_provider_name" {
  value     = module.gh_oidc.provider_name
  sensitive = true
}

output "gh_sa_email" {
  value     = google_service_account.sa.email
  sensitive = true
}
