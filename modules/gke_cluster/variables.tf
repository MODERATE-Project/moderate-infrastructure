variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zones" {
  type = list(string)
}

variable "cluster_subnet_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "cluster_subnet_pods_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "cluster_subnet_services_cidr" {
  type    = string
  default = "10.11.0.0/16"
}

variable "nodes_machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "nodes_min_count" {
  type    = number
  default = 1
}

variable "nodes_max_count" {
  type    = number
  default = 2
}

variable "registry_project_ids" {
  type        = list(string)
  description = "Projects holding Artifact Registries"
  default     = []
}
