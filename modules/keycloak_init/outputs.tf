output "moderate_realm_name" {
  value = local.moderate_realm
}

output "apisix_client_id" {
  value = local.apisix_client_id
}

output "apisix_client_secret" {
  value = random_password.apisix_client_secret.result
}

output "apisix_client_resource_yatai" {
  value = local.apisix_client_resource_yatai
}

output "apisix_client_resource_moderate_api" {
  value = local.apisix_client_resource_moderate_api
}

output "open_metadata_client_id" {
  value = local.open_metadata_client_id
}

output "open_metadata_client_secret" {
  value = random_password.open_metadata_client_secret.result
}

output "platform_api_username" {
  value = local.moderate_api_username
}

output "platform_api_password" {
  value = random_password.moderate_api_password.result
}
