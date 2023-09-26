locals {
  mongo_host = "${kubernetes_service.mongo.metadata[0].name}.${local.namespace}.svc.cluster.local"
  mongo_port = kubernetes_service.mongo.spec[0].port[0].port
}

output "mongo_internal_host" {
  value = local.mongo_host
}

output "mongo_internal_port" {
  value = local.mongo_port
}

output "mongo_internal_url" {
  value     = "mongodb://${local.mongo_host}:${local.mongo_port}"
  sensitive = true
}
