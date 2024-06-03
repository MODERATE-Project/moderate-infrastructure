variable "namespace" {
  type        = string
  default     = null
  description = "Namespace where the resources will be created"
}

variable "mongo_username" {
  type        = string
  description = "Username for the MongoDB database"
}

variable "mongo_password" {
  type        = string
  description = "Password for the MongoDB database"
  sensitive   = true
}

variable "mongo_endpoint" {
  type        = string
  description = "Endpoint of the MongoDB database"
}

variable "mongo_database" {
  type        = string
  description = "Name of the MongoDB database"
  default     = "moderatetrust"
}

variable "l2_private_key" {
  type        = string
  description = "Private key of the wallet that will act as the proxy for the IOTA network"
  sensitive   = true
}
