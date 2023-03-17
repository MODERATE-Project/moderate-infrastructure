variable "ingress_nginx_chart_version" {
  type    = string
  default = "4.5.2"
}

# Example:
# [
#   {
#     public_port  = 1883,
#     kube_service = "mqtt_namespace/mosquitto:1883"
#   }
# ]
variable "tcp_services" {
  type = list(object({
    public_port  = number
    kube_service = string
  }))

  default = null
}

variable "cluster_admin_account" {
  type        = string
  description = "Google Cloud account as reported by 'gcloud config get-value account'"
}

variable "gke_network_name" {
  type = string
}

variable "gke_master_ipv4_cidr_block" {
  type = string
}
