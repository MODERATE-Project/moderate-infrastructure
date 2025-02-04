output "instance_name" {
  description = "The name of the Compute instance"
  value       = google_compute_instance.dev_instance.name
}

output "instance_external_ip" {
  description = "The external IP address of the Compute instance"
  value       = google_compute_instance.dev_instance.network_interface[0].access_config[0].nat_ip
}

output "static_ip_address" {
  description = "The reserved static IP address"
  value       = google_compute_address.static_ip.address
}
