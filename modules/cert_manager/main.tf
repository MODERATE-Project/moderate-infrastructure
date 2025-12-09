resource "kubernetes_namespace" "cert_manager" {
  metadata {
    annotations = {
      name = "cert-manager"
    }
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version
  namespace  = kubernetes_namespace.cert_manager.id

  set = [
    {
      name  = "installCRDs"
      value = true
    }
  ]
}

# Give a few seconds for the cert-manager CRDs to be created

resource "time_sleep" "wait_after_helm_cert_manager" {
  depends_on      = [helm_release.cert_manager]
  create_duration = var.after_install_crds_sleep
}
