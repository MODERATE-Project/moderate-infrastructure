variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_network_id" {
  type = string
}

variable "transaction_log_retention_days" {
  type    = number
  default = 2
}

variable "retained_backups" {
  type    = number
  default = 5
}

variable "database_version" {
  type    = string
  default = "POSTGRES_14"
}

variable "disk_size_gb" {
  type    = number
  default = 10
}

variable "disk_autoresize_limit" {
  type    = number
  default = 50
}
