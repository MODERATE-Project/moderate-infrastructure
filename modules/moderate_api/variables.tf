variable "project_id" {
  type        = string
  description = "Project ID that will contain the resources"
}

variable "region" {
  type        = string
  description = "Region where the resources will be created"
}

variable "namespace" {
  type        = string
  default     = null
  description = "Namespace where the resources will be created"
}

variable "cloud_sql_instance_name" {
  type        = string
  description = "Name of the Cloud SQL instance"
}

variable "cloud_sql_instance_connection_name" {
  type        = string
  description = "Connection name of the Cloud SQL instance"
}

variable "trust_service_endpoint_url" {
  type        = string
  description = "URL of the Trust Services endpoint"
}

variable "domain_ui" {
  type = string
}

variable "cert_manager_issuer" {
  type = string
}

variable "open_metadata_endpoint_url" {
  type        = string
  description = "Base URL of the Open Metadata API"
}

variable "open_metadata_bearer_token" {
  type        = string
  description = "Bearer token for the Open Metadata API"
  default     = null
}

variable "ui_proxy_body_size" {
  type        = string
  default     = "256m"
  description = "Maximum body size for the UI proxy"
}
