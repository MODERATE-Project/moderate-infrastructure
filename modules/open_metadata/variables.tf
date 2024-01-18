variable "namespace" {
  type        = string
  default     = null
  description = "Namespace to deploy the Open Metadata service into"
}

variable "open_metadata_chart_version" {
  type        = string
  default     = "1.2.7"
  description = "Open Metadata Helm chart version"
}

variable "open_metadata_log_level" {
  type        = string
  default     = "INFO"
  description = "Open Metadata log level"
}

variable "authorizer_principal_domain" {
  type        = string
  default     = "moderate.cloud"
  description = "Authorizer principal domain"
}

variable "initial_admin_usernames" {
  type        = list(string)
  default     = ["admin"]
  description = "Initial admin usernames"
}

variable "keycloak_url" {
  type        = string
  description = "URL of the Keycloak service used for SSO including scheme (e.g. https://keycloak.moderate.cloud)"
}

variable "keycloak_realm" {
  type        = string
  default     = "moderate"
  description = "Keycloak realm that contains the Open Metadata SSO client"
}

variable "open_metadata_keycloak_client_id" {
  type        = string
  default     = "openmetadata"
  description = "Keycloak client ID for the Open Metadata SSO client"
}

variable "cloud_sql_instance_name" {
  type        = string
  description = "Cloud SQL instance name"
}

variable "postgres_host" {
  type        = string
  description = "Postgres host"
}

variable "postgres_port" {
  type        = number
  default     = 5432
  description = "Postgres port"
}

variable "ingress_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable ingress for the Open Metadata service"
}

variable "open_metadata_domain" {
  type        = string
  description = "Open Metadata domain"
}

variable "cert_manager_issuer" {
  type        = string
  description = "cert-manager issuer to use for the Open Metadata web app"
}

variable "elastic_volume_size_gi" {
  type        = number
  default     = 30
  description = "Size of the persistent volume in GiB for the Elasticsearch service"
}
