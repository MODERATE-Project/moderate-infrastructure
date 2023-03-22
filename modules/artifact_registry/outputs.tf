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

# https://cloud.google.com/artifact-registry/docs/docker/authentication#json-key

output "docker_registry_server" {
  value = "${google_artifact_registry_repository.image_repository.location}-docker.pkg.dev"
}

output "docker_registry_repository_name" {
  value = google_artifact_registry_repository.image_repository.name
}

output "docker_registry_username" {
  value = "_json_key_base64"
}

output "docker_registry_password" {
  value     = google_service_account_key.sa_artifact_registry_key.private_key
  sensitive = true
}
