locals {
  output_host = "${kubernetes_service.rabbit.metadata[0].name}.${local.namespace}.svc.cluster.local"
  output_port = kubernetes_service.rabbit.spec[0].port[0].port
  output_pass = random_password.rabbit_admin_password.result
}

output "rabbit_private_url" {
  value     = "amqp://${local.rabbit_user}:${local.output_pass}@${local.output_host}:${local.output_port}/"
  sensitive = true
}
