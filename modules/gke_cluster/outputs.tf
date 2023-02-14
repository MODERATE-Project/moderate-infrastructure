output "kubernetes_host" {
  value     = "https://${module.gke.endpoint}"
  sensitive = true
}

output "kubernetes_cluster_ca_cert" {
  value     = base64decode(module.gke.ca_certificate)
  sensitive = true
}
