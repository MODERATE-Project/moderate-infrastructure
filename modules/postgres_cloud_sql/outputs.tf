output "sql_instance_name" {
  value = google_sql_database_instance.postgres_sql_instance.name
}

output "sql_instance_connection_name" {
  value = google_sql_database_instance.postgres_sql_instance.connection_name
}
