variable "namespace" {
  type        = string
  default     = null
  description = "Namespace where the resources will be created."
}

variable "backoff_limit" {
  type        = number
  description = "The number of retries before considering the job as failed."
  default     = 12
}

variable "keycloak_admin_user" {
  type        = string
  description = "The username of the Keycloak admin."
  default     = "admin"
}

variable "keycloak_admin_pass" {
  type        = string
  description = "The password of the Keycloak admin."
  sensitive   = true
}

variable "keycloak_url" {
  type        = string
  description = "The base API URL of Keycloak."
}

variable "open_metadata_root_url" {
  type        = string
  description = "Root URL of the Open Metadata service."
}

variable "api_username" {
  type        = string
  description = "The username of the API user."
  default     = "tfapiuser"
}

variable "platform_ui_url" {
  type        = string
  description = "The URL of the platform UI."
}
