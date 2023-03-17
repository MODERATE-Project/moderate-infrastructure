output "cluster_issuer_staging_name" {
  value = local.issuer_staging
}

output "cluster_issuer_staging_secret_name" {
  value = local.issuer_secret_staging
}

output "cluster_issuer_prod_name" {
  value = local.issuer_prod
}

output "cluster_issuer_prod_secret_name" {
  value = local.issuer_secret_prod
}

output "gsa_dns_solver_email" {
  value = google_service_account.gsa_dns_solver.email
}
