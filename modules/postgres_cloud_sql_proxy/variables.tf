variable "project_id" {
  type = string
}

variable "cloud_sql_connection_name" {
  type = string
}

variable "namespace" {
  type    = string
  default = null
}

variable "replicas" {
  type    = number
  default = 1
}
