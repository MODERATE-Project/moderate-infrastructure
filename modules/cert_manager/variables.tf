variable "after_install_crds_sleep" {
  type    = string
  default = "90s"
}

variable "cert_manager_chart_version" {
  type    = string
  default = "1.11.0"
}

variable "cluster_admin_account" {
  type        = string
  description = "Google Cloud account as reported by 'gcloud config get-value account'"
}

variable "use_dns01_google_cloud_dns" {
  type    = bool
  default = false
}

variable "project_id_cloud_dns" {
  type    = string
  default = null
}
