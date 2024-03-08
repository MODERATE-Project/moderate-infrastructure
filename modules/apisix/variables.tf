variable "namespace" {
  type        = string
  default     = null
  description = "Namespace where the APISIX resources will be deployed."
}

variable "cert_manager_issuer" {
  type        = string
  description = "The name of the cert-manager issuer to use for TLS certificates."
}

variable "yatai_proxy_node" {
  type        = string
  description = "The node of the NGINX proxy to the Yatai inference APIs."
}

variable "moderate_api_node" {
  type        = string
  description = "The node of the Moderate API (e.g. api-service.moderate-api.svc.cluster.local:8000)."
}

variable "base_domain" {
  type        = string
  description = "Base domain for the rest of the subdomains."
}

variable "base_subdomain" {
  type        = string
  default     = "gw"
  description = "Name of the base subdomain that acts as a prefix for the rest of the subdomains."
}

variable "docs_subdomain" {
  type        = string
  default     = "docs"
  description = "Name of the subdomain for the documentation."
}

variable "yatai_subdomain" {
  type        = string
  default     = "bento"
  description = "Name of the subdomain for the Yatai inference APIs."
}

variable "keycloak_subdomain" {
  type        = string
  default     = "keycloak"
  description = "Name of the subdomain for the Keycloak authentication service."
}

variable "moderate_api_subdomain" {
  type        = string
  default     = "api"
  description = "Name of the subdomain for the MODERATE HTTP API."
}

variable "keycloak_realm" {
  type        = string
  description = "Name of the Keycloak realm to use for authentication."
}

variable "keycloak_client_id" {
  type        = string
  description = "Name of the Keycloak client that represents APISIX."
}

variable "keycloak_client_secret" {
  type        = string
  sensitive   = true
  description = "Secret of the Keycloak client that represents APISIX."
}

variable "keycloak_permissions_yatai" {
  type        = string
  description = "Name of the Keycloak resource that represents the Yatai inference APIs."
}

variable "keycloak_permissions_moderate_api" {
  type        = string
  description = "Name of the Keycloak resource that represents the Moderate API."
}

variable "proxy_body_size" {
  type        = string
  default     = "1024m"
  description = "Maximum allowed size of the client request body. This is an explicit limit on the size of the uploaded files."
}

variable "cors_allow_origins" {
  type        = list(string)
  default     = ["*"]
  description = "Origins to allow CORS."
}
