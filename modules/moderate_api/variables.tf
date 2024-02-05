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
