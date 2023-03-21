output "sql_instance_name" {
  value = google_sql_database_instance.postgres_sql_instance.name
}

output "cloud_sql_proxy_service" {
  value = "${one(kubernetes_service.cloud_sql.metadata[*].name)}.${one(kubernetes_service.cloud_sql.metadata[*].namespace)}.svc.cluster.local"
}
