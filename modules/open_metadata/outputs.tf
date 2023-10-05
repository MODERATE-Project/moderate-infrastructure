locals {
  svc_cluster_name = "${local.open_metadata_full_name}.${local.namespace}.svc.cluster.local"
}

output "open_metadata_service_host" {
  value = local.svc_cluster_name
}

output "open_metadata_service_port" {
  value = local.open_metadata_port
}

output "open_metadata_service_host_port" {
  value = "${local.svc_cluster_name}:${local.open_metadata_port}"
}

output "open_metadata_admin_service_host_port" {
  value = "${local.svc_cluster_name}:${local.open_metadata_admin_port}"
}
