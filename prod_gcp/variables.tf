variable "project_id" {
  type        = string
  description = "Globally unique identifier for this project in Google Cloud"
}

variable "region" {
  type        = string
  description = "Google Cloud Compute Engine region"
  default     = "europe-west1"
}

variable "zone_default" {
  type        = string
  description = "Default zone within the Google Cloud region"
  default     = "europe-west1-b"
}

variable "zones" {
  type        = list(string)
  description = "Available zones within the Google Cloud region"
  default     = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
}
