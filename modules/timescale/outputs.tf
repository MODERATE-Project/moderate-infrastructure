locals {
  ts_host = "${kubernetes_service.timescale.metadata[0].name}.${local.namespace}.svc.cluster.local"
  ts_port = kubernetes_service.timescale.spec[0].port[0].port
  ts_user = "postgres"
  ts_pass = random_password.timescale_postgres_password.result
}

output "timescale_internal_host" {
  value = local.ts_host
}

output "timescale_internal_port" {
  value = local.ts_port
}

output "timescale_postgres_user_password" {
  value     = local.ts_pass
  sensitive = true
}

output "timescale_internal_uri" {
  value     = "postgres://${local.ts_user}:${local.ts_pass}@${local.ts_host}:${local.ts_port}/${var.default_db}"
  sensitive = true
}
