output "cloud_sql_proxy_service" {
  value = "${one(kubernetes_service.cloud_sql.metadata[*].name)}.${one(kubernetes_service.cloud_sql.metadata[*].namespace)}.svc.cluster.local"
}
