variable "namespace" {
  type        = string
  description = "Namespace where the Kubernetes Service Account with Cloud DNS access will be created"
}

variable "gke_cluster_project_id" {
  type        = string
  description = "ID of the project that contains the GKE cluster"
}

variable "cloud_dns_project_id" {
  type        = string
  description = "ID of the project that contains the Cloud DNS service"
}
