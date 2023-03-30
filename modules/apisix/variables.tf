variable "cert_manager_issuer" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "base_subdomain" {
  type    = string
  default = "api"
}

variable "docs_subdomain" {
  type    = string
  default = "docs"
}

variable "namespace" {
  type    = string
  default = null
}
