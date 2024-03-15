variable "namespace" {
  type    = string
  default = null
}

variable "domain" {
  type = string
}

variable "cert_manager_issuer" {
  type = string
}

variable "geoserver_url" {
  type        = string
  description = "Cluster-internal URL of the common GeoServer service"
}
