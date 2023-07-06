locals {
  proxy_service_name = one(kubernetes_service.nginx.metadata[*].name)
}

output "proxy_service_host_port" {
  value = "${local.proxy_service_name}.${local.namespace}.svc.cluster.local:${local.nginx_port}"
}
