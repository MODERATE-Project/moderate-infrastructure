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

variable "docker_registry_server" {
  type = string
}

variable "docker_registry_username" {
  type = string
}

variable "docker_registry_password" {
  type      = string
  sensitive = true
}

variable "docker_registry_secure" {
  type    = bool
  default = true
}

variable "docker_bento_repository_name" {
  type = string
}
