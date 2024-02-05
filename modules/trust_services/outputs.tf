locals {
  output_host = "${kubernetes_service.moderate_trust.metadata[0].name}.${local.namespace}.svc.cluster.local"
  output_port = kubernetes_service.moderate_trust.spec[0].port[0].port
}

output "trust_internal_url" {
  value = "http://${local.output_host}:${local.output_port}"
}
