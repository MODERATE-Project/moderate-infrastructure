variable "after_install_crds_sleep" {
  type    = string
  default = "30s"
}

variable "cert_manager_chart_version" {
  type    = string
  default = "1.11.0"
}

variable "cluster_admin_account" {
  type        = string
  description = "Google Cloud account as reported by 'gcloud config get-value account'"
}
