variable "project_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "cert_manager_issuer" {
  type = string
}

variable "cloud_sql_instance_name" {
  type = string
}

variable "cloud_sql_instance_connection_name" {
  type = string
}

variable "namespace" {
  type    = string
  default = null
}
