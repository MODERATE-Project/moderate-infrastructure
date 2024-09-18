variable "namespace" {
  type        = string
  default     = null
  description = "Namespace to deploy the Dagster service into"
}

variable "dagster_chart_version" {
  type        = string
  default     = "1.8.7"
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

variable "ingress_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable ingress for the Dagster web UI"
}

variable "open_metadata_host" {
  type        = string
  description = "Host for the Open Metadata service (including the scheme)"
}

variable "open_metadata_port" {
  type        = number
  default     = 8585
  description = "Port for the Open Metadata service"
}

variable "open_metadata_token" {
  type        = string
  default     = null
  description = "JWT token of the Open Metadata ingestion bot. This needs to be defined manually after the first deployment."
}

variable "platform_api_url" {
  type        = string
  description = "The base URL of the platform API"
}

variable "platform_api_username" {
  type        = string
  description = "The username of the platform API"
}

variable "platform_api_password" {
  type        = string
  description = "The password of the platform API"
  sensitive   = true
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to be profiled by OpenMetadata"
}

variable "s3_access_key" {
  type        = string
  description = "Access key of the S3 service"
}

variable "s3_secret_key" {
  type        = string
  description = "Secret key of the S3 service"
  sensitive   = true
}

variable "s3_endpoint_url" {
  type        = string
  description = "Endpoint URL of the S3 service"
  default     = "https://storage.googleapis.com"
}

variable "s3_region" {
  type        = string
  description = "Region of the S3 service"
  default     = "auto"
}
