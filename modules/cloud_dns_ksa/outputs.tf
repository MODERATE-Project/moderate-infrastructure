output "ksa_name" {
  value = local.ksa_dns_name
}

output "gsa_email" {
  value = google_service_account.gsa_dns_solver.email
}
