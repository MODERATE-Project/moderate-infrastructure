output "api_service_host_port" {
  value = "${local.service_name}.${local.namespace}.svc.cluster.local:${local.api_port}"
}
