locals {
  main_node_pool_name = "main-node-pool"
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.project_id
  name                       = "gke-cluster"
  region                     = var.region
  zones                      = var.zones
  network                    = google_compute_network.gke_cluster_network.name
  subnetwork                 = google_compute_subnetwork.gke_cluster_subnetwork.name
  ip_range_pods              = local.range_name_pods
  ip_range_services          = local.range_name_services
  http_load_balancing        = true
  network_policy             = true
  horizontal_pod_autoscaling = true
  enable_private_endpoint    = false
  enable_private_nodes       = true
  remove_default_node_pool   = true

  node_pools = [
    {
      name            = local.main_node_pool_name
      machine_type    = var.nodes_machine_type
      node_locations  = join(",", var.zones)
      min_count       = var.nodes_min_count
      max_count       = var.nodes_max_count
      local_ssd_count = 0
      spot            = false
      disk_size_gb    = 80
      disk_type       = "pd-standard"
      enable_gcfs     = false
      enable_gvnic    = false
      auto_repair     = true
      auto_upgrade    = true
      preemptible     = false
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}

    "${local.main_node_pool_name}" = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}
  }

  node_pools_taints = {
    all = []

    "${local.main_node_pool_name}" = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    "${local.main_node_pool_name}" = [
      "default-node-pool",
    ]
  }
}
