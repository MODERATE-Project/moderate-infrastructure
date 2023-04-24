output "namespace" {
  value = local.namespace
}

output "proxy_service_name" {
  value = one(kubernetes_service.nginx.metadata[*].name)
}
