variable "backoff_limit" {
  type        = number
  description = "The number of retries before considering the job as failed."
  default     = 10
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
