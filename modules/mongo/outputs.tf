locals {
  mongo_host = "${kubernetes_service.mongo.metadata[0].name}.${local.namespace}.svc.cluster.local"
  mongo_port = kubernetes_service.mongo.spec[0].port[0].port
  mongo_pass = random_password.mongo_admin_password.result
}

output "mongo_internal_host" {
  value = local.mongo_host
}

output "mongo_internal_port" {
  value = local.mongo_port
}

output "mongo_admin_user" {
  value = local.mongo_admin_user
}

output "mongo_admin_pass" {
  value     = local.mongo_pass
  sensitive = true
}

output "mongo_internal_url" {
  value     = "mongodb://${local.mongo_admin_user}:${local.mongo_pass}@${local.mongo_host}:${local.mongo_port}/?authSource=admin"
  sensitive = true
}
