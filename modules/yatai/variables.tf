variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "google_sql_database_instance_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "cert_manager_issuer" {
  type = string
}

variable "postgres_host" {
  type = string
}

variable "postgres_port" {
  type    = number
  default = 5432
}

variable "namespace" {
  type    = string
  default = null
}
