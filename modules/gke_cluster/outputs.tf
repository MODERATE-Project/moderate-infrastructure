output "kubernetes_host" {
  value     = "https://${module.gke.endpoint}"
  sensitive = true
}

output "kubernetes_cluster_ca_cert" {
  value     = base64decode(module.gke.ca_certificate)
  sensitive = true
}

output "master_ipv4_cidr_block" {
  value = module.gke.master_ipv4_cidr_block
}

output "cluster_network_name" {
  value = module.gcp_network.network_name
}

output "cluster_network_id" {
  value = module.gcp_network.network_id
}
