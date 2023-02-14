resource "google_compute_network" "gke_cluster_network" {
  name = "gke-vpc-network"
}

locals {
  range_name_pods     = "gke-secondary-range-pods"
  range_name_services = "gke-secondary-range-services"
}

resource "google_compute_subnetwork" "gke_cluster_subnetwork" {
  name          = "gke-subnetwork"
  ip_cidr_range = var.cluster_subnet_cidr
  region        = var.region
  network       = google_compute_network.gke_cluster_network.id

  secondary_ip_range {
    range_name    = local.range_name_pods
    ip_cidr_range = var.cluster_subnet_pods_cidr
  }

  secondary_ip_range {
    range_name    = local.range_name_services
    ip_cidr_range = var.cluster_subnet_services_cidr
  }
}

resource "google_compute_router" "gke_cluster_router" {
  name    = "gke-cluster-router"
  region  = google_compute_subnetwork.gke_cluster_subnetwork.region
  network = google_compute_network.gke_cluster_network.id
}

resource "google_compute_router_nat" "gke_cluster_nat" {
  name                               = "gke-cluster-nat"
  router                             = google_compute_router.gke_cluster_router.name
  region                             = google_compute_router.gke_cluster_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
