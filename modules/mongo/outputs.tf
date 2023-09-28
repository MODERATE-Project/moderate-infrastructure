locals {
  output_host = "${kubernetes_service.mongo.metadata[0].name}.${local.namespace}.svc.cluster.local"
  output_port = kubernetes_service.mongo.spec[0].port[0].port
  output_pass = random_password.mongo_admin_password.result
}

output "mongo_internal_host" {
  value = local.output_host
}

output "mongo_internal_port" {
  value = local.output_port
}

output "mongo_admin_user" {
  value = local.mongo_admin_user
}

output "mongo_admin_pass" {
  value     = local.output_pass
  sensitive = true
}

output "mongo_internal_url" {
  value     = "mongodb://${local.mongo_admin_user}:${local.output_pass}@${local.output_host}:${local.output_port}/?authSource=admin"
  sensitive = true
}
