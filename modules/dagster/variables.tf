variable "namespace" {
  type        = string
  default     = null
  description = "Namespace to deploy the Dagster service into"
}

variable "dagster_chart_version" {
  type        = string
  default     = "1.4.14"
  description = "Dagster Helm chart version"
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

variable "keycloak_url" {
  type        = string
  description = "The base API URL of Keycloak"
}

variable "keycloak_admin_user" {
  type        = string
  description = "The username of the Keycloak admin"
}

variable "keycloak_admin_pass" {
  type        = string
  description = "The password of the Keycloak admin"
  sensitive   = true
}

variable "domain" {
  type        = string
  description = "Public domain for the Dagster web UI"
}

variable "cert_manager_issuer" {
  type        = string
  description = "cert-manager issuer to use for the Dagster web UI"
}
