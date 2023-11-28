locals {
  range_name_pods     = "gke-secondary-range-pods"
  range_name_services = "gke-secondary-range-services"
  network_name        = "gke-vpc-network"
  subnetwork_name     = "gke-subnetwork"
}

module "gcp_network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 7.5"

  project_id   = var.project_id
  network_name = local.network_name

  subnets = [
    {
      subnet_name           = local.subnetwork_name
      subnet_ip             = var.cidr_subnet
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    (local.subnetwork_name) = [
      {
        range_name    = local.range_name_pods
        ip_cidr_range = var.cidr_cluster_pods
      },
      {
        range_name    = local.range_name_services
        ip_cidr_range = var.cidr_cluster_services
      },
    ]
  }
}

data "google_compute_subnetwork" "subnetwork" {
  name       = local.subnetwork_name
  project    = var.project_id
  region     = var.region
  depends_on = [module.gcp_network]
}

resource "google_compute_router" "gke_cluster_router" {
  name    = "gke-cluster-router"
  region  = module.gcp_network.subnets_regions[0]
  network = module.gcp_network.network_id
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
