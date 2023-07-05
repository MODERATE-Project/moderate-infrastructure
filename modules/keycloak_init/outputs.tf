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
