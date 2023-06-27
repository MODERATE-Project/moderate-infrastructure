variable "cert_manager_issuer" {
  type = string
}

variable "yatai_namespace" {
  type = string
}

variable "yatai_proxy_service" {
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

variable "yatai_subdomain" {
  type    = string
  default = "bento"
}

variable "namespace" {
  type    = string
  default = null
}

variable "keycloak_subdomain" {
  type    = string
  default = "keycloak"
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_client_id" {
  type = string
}

variable "keycloak_client_secret" {
  type      = string
  sensitive = true
}

variable "keycloak_permissions_yatai" {
  type = string
}
