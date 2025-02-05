resource "google_compute_address" "static_ip" {
  name   = var.static_ip_name
  region = var.region
}

resource "google_compute_firewall" "dev_instance_ssh_ingress" {
  name          = "${var.instance_name}-allow-ssh-http"
  network       = var.network
  direction     = "INGRESS"
  priority      = 1000
  target_tags   = [var.instance_name]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }
}

resource "google_compute_instance" "dev_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.boot_disk_size
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      // This attaches the reserved static IP to the instance
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    "ssh-keys" = "${var.devuser}:${var.devuser_ssh_public_key}"
  }

  tags = concat(var.instance_tags, [var.instance_name])
}
