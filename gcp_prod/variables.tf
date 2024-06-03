# Attribution to: https://stackoverflow.com/a/67210655
variable "project_gcp_service_list" {
  description = "The list of APIs necessary for the project"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "logging.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "gkebackup.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com"
  ]
}

variable "project_id" {
  type        = string
  description = "Globally unique identifier for this project in Google Cloud"
}

variable "project_id_common" {
  type        = string
  description = "Identifier of the project for common resources (e.g. Artifact Registry)"
}

variable "region" {
  type        = string
  description = "Google Cloud Compute Engine region"
  default     = "europe-west1"
}

variable "zone_default" {
  type        = string
  description = "Default zone within the Google Cloud region"
  default     = "europe-west1-b"
}

variable "zones" {
  type        = list(string)
  description = "Available zones within the Google Cloud region"
  default     = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
}

variable "docker_registry_server" {
  type        = string
  description = "URL of the container registry without the HTTP/S scheme"
  default     = "europe-west1-docker.pkg.dev"
}

variable "docker_registry_username" {
  type        = string
  description = "Username of the container registry"
}

variable "docker_registry_password" {
  type        = string
  description = "Password for the username of the container registry"
  sensitive   = true
}

variable "artifact_registry_repository_name" {
  type        = string
  description = "Name of the repository in Artifact Registry"
}

variable "base_domain" {
  type        = string
  description = "The base public DNS domain that serves as the origin for all other subdomains"
}

variable "domain_docs" {
  type        = string
  description = "Public DNS domain of the MODERATE documentation site"
}

variable "domain_yatai" {
  type        = string
  description = "Public DNS domain of the Yatai service"
}

variable "domain_keycloak" {
  type        = string
  description = "Public DNS domain of the Keycloak service"
}

variable "domain_geoserver" {
  type        = string
  description = "Public DNS domain of the Geoserver service"
}

variable "domain_dagster" {
  type        = string
  description = "Public DNS domain of the Dagster web UI"
}

variable "domain_open_metadata" {
  type        = string
  description = "Public DNS domain of the Open Metadata web application"
}

variable "domain_platform_ui" {
  type        = string
  description = "Public DNS domain of the Platform Web UI"
}

variable "domain_tool_lec" {
  type        = string
  description = "Public DNS domain of the LEC Location Assessment tool"
}

variable "open_metadata_token" {
  type        = string
  default     = null
  description = "Token of the Open Metadata ingestion bot. This should be defined after the deployment as the token has to be retrieved manually from the Open Metadata web UI."
}

variable "nodes_min_count" {
  type        = number
  description = "Minimum number of nodes per zone in the Kubernetes cluster"
  default     = 1
}

variable "nodes_max_count" {
  type        = number
  description = "Maximum number of nodes per zone in the Kubernetes cluster"
  default     = 2
}

variable "trust_l2_private_key" {
  type        = string
  description = "Private key of the wallet that will act as the proxy for the IOTA network"
  sensitive   = true
}
