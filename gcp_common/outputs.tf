output "repository_id" {
  value = module.artifact_registry.repository_id
}

output "repository_name" {
  value = module.artifact_registry.repository_name
}

output "repository_location" {
  value = module.artifact_registry.repository_location
}

output "gh_oidc_pool_name" {
  value = module.artifact_registry.gh_oidc_pool_name
}

output "gh_oidc_provider_name" {
  value     = module.artifact_registry.gh_oidc_provider_name
  sensitive = true
}

output "gh_sa_email" {
  value     = module.artifact_registry.gh_sa_email
  sensitive = true
}
