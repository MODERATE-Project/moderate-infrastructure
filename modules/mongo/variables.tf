variable "namespace" {
  type        = string
  default     = null
  description = "Namespace to deploy the MongoDB instance into"
}

variable "volume_size_gi" {
  type        = number
  default     = 30
  description = "Size of the persistent volume in GiB"
}
