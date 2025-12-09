resource "kubernetes_cluster_role_binding" "cluster_admin_binding" {
  metadata {
    name = "cluster-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = var.cluster_admin_account
  }
}

resource "google_compute_firewall" "ingress_nginx_firewall" {
  name    = "nginx-controller-gke-firewall"
  network = var.gke_network_name

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }

  direction     = "INGRESS"
  source_ranges = [var.gke_master_ipv4_cidr_block]
}

resource "helm_release" "ingress_nginx" {
  depends_on = [
    kubernetes_cluster_role_binding.cluster_admin_binding
  ]

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version

  values = var.tcp_services == null ? [
    <<-EOF
      tcp:
    EOF
  ] : null

  set = var.tcp_services == null ? [] : [
    for svc in var.tcp_services : {
      name  = "tcp.${svc["public_port"]}"
      value = svc["kube_service"]
    }
  ]
}
