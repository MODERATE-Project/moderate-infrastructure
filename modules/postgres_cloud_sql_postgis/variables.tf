variable "postgres_host" {
  type        = string
  description = "The connection URL of the Cloud SQL PostgreSQL database."
}

variable "postgres_port" {
  type        = number
  description = "The port of the Cloud SQL PostgreSQL database."
  default     = 5432
}

variable "google_sql_database_instance_name" {
  type        = string
  description = "The name of the Cloud SQL PostgreSQL database instance."
}
