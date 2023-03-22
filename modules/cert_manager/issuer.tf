locals {
  issuer_staging        = "letsencrypt-staging"
  issuer_prod           = "letsencrypt-prod"
  issuer_secret_staging = "letsencrypt-staging"
  issuer_secret_prod    = "letsencrypt-prod"
}

# Annotation cluster-autoscaler.kubernetes.io/safe-to-evict is required due to GKE autoscaler issues:
# https://github.com/cert-manager/cert-manager/issues/5267

resource "kubectl_manifest" "letsencrypt_staging_issuer" {
  depends_on = [time_sleep.wait_after_helm_cert_manager]
  wait       = true

  yaml_body = <<-EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: ${local.issuer_staging}
    spec:
      acme:
        server: https://acme-staging-v02.api.letsencrypt.org/directory
        email: ${var.cluster_admin_account}
        privateKeySecretRef:
          name: ${local.issuer_secret_staging}
        solvers:
        - http01:
            ingress:
              class: nginx
              podTemplate:
                metadata:
                  annotations:
                    cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
    EOF
}

resource "kubectl_manifest" "letsencrypt_prod_issuer" {
  depends_on = [time_sleep.wait_after_helm_cert_manager]
  wait       = true

  yaml_body = <<-EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: ${local.issuer_prod}
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: ${var.cluster_admin_account}
        privateKeySecretRef:
          name: ${local.issuer_secret_prod}
        solvers:
        - http01:
            ingress:
              class: nginx
              podTemplate:
                metadata:
                  annotations:
                    cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
    EOF
}
