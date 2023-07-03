variable "namespace" {
  type        = string
  default     = null
  description = "Namespace to deploy the Timescale instance into"
}

variable "default_db" {
  type        = string
  default     = "timeseries"
  description = "Name for the default database"
}

variable "volume_size_gi" {
  type        = number
  default     = 30
  description = "Size of the persistent volume in GiB"
}

variable "grafana_enable" {
  type        = bool
  default     = false
  description = "Wheter to deploy a companion Grafana dashboard for browsing Timescale metrics"
}

variable "grafana_admin_user" {
  type        = string
  default     = "admin"
  description = "Username for the Grafana admin user"
}

variable "grafana_cert_manager_issuer" {
  type        = string
  default     = null
  description = "Name of the cert-manager issuer to use for the Grafana TLS certificate"
}

variable "grafana_domain" {
  type        = string
  default     = null
  description = "Domain to use for the Grafana dashboard"
}
