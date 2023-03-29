variable "cert_manager_issuer" {
  type = string
}

variable "domain" {
  type = string
}

variable "namespace" {
  type    = string
  default = null
}
