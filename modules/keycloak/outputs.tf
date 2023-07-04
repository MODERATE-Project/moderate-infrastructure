output "keycloak_admin_user" {
  value = local.admin_user
}

output "keycloak_admin_pass" {
  value = random_password.password_admin_keycloak.result
}

output "keycloak_service_host_port" {
  value = "${local.service_name}.${local.namespace}.svc.cluster.local:${local.service_port}"
}
