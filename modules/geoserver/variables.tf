variable "namespace" {
  type        = string
  default     = null
  description = "Kubernetes namespace to deploy Geoserver to."
}

variable "domain" {
  type        = string
  description = "Domain name to use for the Geoserver service."
}

variable "cert_manager_issuer" {
  type        = string
  description = "Name of the issuer that will be used to generate the TLS certificate for the Geoserver service."
}

variable "stable_extensions" {
  type        = string
  default     = "excel-plugin,charts-plugin"
  description = "List of stable plugins to install. See: https://github.com/kartoza/docker-geoserver/blob/master/build_data/stable_plugins.txt"
}

variable "community_extensions" {
  type        = string
  default     = ""
  description = "List of community plugins to install. See: https://github.com/kartoza/docker-geoserver/blob/master/build_data/community_plugins.txt"
}

variable "volume_size_gi" {
  type        = number
  default     = 20
  description = "Size of the persistent volume in GiB."
}
