variable "project_id" {
  type        = string
  description = "Globally unique identifier for this project in Google Cloud"
}

variable "region" {
  type        = string
  description = "Google Cloud Compute Engine region"
  default     = "europe-west1"
}
