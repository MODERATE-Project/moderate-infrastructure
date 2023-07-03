variable "namespace" {
  type        = string
  default     = null
  description = "Namespace to deploy the Timescale instance into"
}

variable "default_db" {
  type        = string
  default     = "timeseries"
  description = "Name for the default database"
}

variable "volume_size_gi" {
  type        = number
  default     = 30
  description = "Size of the persistent volume in GiB"
}
