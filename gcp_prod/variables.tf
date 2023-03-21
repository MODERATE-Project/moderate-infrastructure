variable "project_id" {
  type        = string
  description = "Globally unique identifier for this project in Google Cloud"
}

variable "project_id_common" {
  type        = string
  description = "Identifier of the project for common resources (e.g. Artifact Registry)"
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

variable "domain_docs" {
  type        = string
  description = "Public DNS domain of the MODERATE documentation site"
}

variable "domain_yatai" {
  type        = string
  description = "Public DNS domain of the Yatai web application"
}
