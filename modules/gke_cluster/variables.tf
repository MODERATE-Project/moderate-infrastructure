variable "project_id" {
  description = "ID of the project where the cluster will be created"
  type        = string
}

variable "region" {
  description = "Region where the cluster will be created"
  type        = string
}

variable "zones" {
  description = "Zones where the cluster will be created"
  type        = list(string)
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = null
}

variable "nodes_machine_type" {
  type        = string
  description = "Machine type for nodes"
  default     = "e2-standard-4"
}

variable "nodes_min_count" {
  type        = number
  description = "Minimum number of nodes in the NodePool. Must be >=0 and <= max_count. Should be used when autoscaling is true. Cannot be used with total limits."
  default     = 1
}

variable "nodes_max_count" {
  type        = number
  description = "Maximum number of nodes in the NodePool. Must be >= min_count. Cannot be used with total limits."
  default     = 2
}

variable "registry_project_ids" {
  type        = list(string)
  description = "Projects holding Artifact Registries"
  default     = []
}

variable "regional" {
  type        = bool
  description = "Whether is a regional cluster"
  default     = true
}

variable "enable_backup" {
  type        = bool
  description = "Whether to enable backup for the cluster"
  default     = false
}

variable "backup_retain_days" {
  type        = number
  description = "Number of days to retain each backup"
  default     = 7
}

variable "backup_delete_lock_days" {
  type        = number
  description = "Minimum number of days which must have passed since a backup was created before it can be deleted"
  default     = 1
}

variable "backup_cron_schedule" {
  type        = string
  description = "Cron schedule for backup"
  default     = "0 2 */1 * *"
}

variable "cidr_subnet" {
  type    = string
  default = "10.0.0.0/17"
}

variable "cidr_cluster_pods" {
  type    = string
  default = "192.168.0.0/18"
}

variable "cidr_cluster_services" {
  type    = string
  default = "192.168.64.0/18"
}

variable "master_ipv4_cidr_block" {
  type    = string
  default = "10.0.128.0/28"
}
