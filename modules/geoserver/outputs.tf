locals {
  geoserver_service_name = kubernetes_service.geoserver.metadata[0].name
}

output "geoserver_service_host_port" {
  value = "${local.geoserver_service_name}.${local.namespace}.svc.cluster.local:${local.geoserver_port}"
}
