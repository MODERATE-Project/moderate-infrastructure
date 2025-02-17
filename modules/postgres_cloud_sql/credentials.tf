locals {
  solar_cadastre_user     = "solarcadastre"
  solar_cadastre_database = "solarcadastre"
}

resource "random_password" "solar_cadastre_password" {
  length  = 20
  special = false
}

resource "google_sql_user" "solar_cadastre_sql_user" {
  instance        = google_sql_database_instance.postgres_sql_instance.name
  name            = local.solar_cadastre_user
  password        = random_password.solar_cadastre_password.result
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "solar_cadastre_sql_database" {
  instance = google_sql_database_instance.postgres_sql_instance.name
  name     = local.solar_cadastre_database
}
