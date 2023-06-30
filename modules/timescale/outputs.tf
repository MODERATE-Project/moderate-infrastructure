output "timescale_cluster_internal_host" {
  value = "${kubernetes_service.timescale.metadata[0].name}.${local.namespace}.svc.cluster.local"
}

output "timescale_cluster_internal_port" {
  value = kubernetes_service.timescale.spec[0].port[0].port
}

output "timescale_postgres_password" {
  value     = random_password.timescale_postgres_password.result
  sensitive = true
}
