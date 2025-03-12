variable "instance_name" {
  description = "Name of the Compute instance"
  type        = string
  default     = "moderate-dev-instance"
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "e2-standard-2"
}

variable "zone" {
  description = "The zone in which the instance will be deployed (e.g., 'europe-west1-b')"
  type        = string
}

variable "region" {
  description = "The region for the instance and the static IP (e.g., 'europe-west1')"
  type        = string
}

variable "image" {
  description = "The boot image for the Compute instance"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "network" {
  description = "The VPC network (self-link or name) for this instance"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to deploy the instance in (self-link or name)"
  type        = string
}

variable "devuser" {
  description = "Username to inject into the instance for SSH access"
  type        = string
  default     = "moderate-dev-user"
}

variable "devuser_ssh_public_key" {
  description = "The SSH public key for devuser (e.g., 'ssh-rsa AAAAB3NzaC1...')"
  type        = string
}

variable "static_ip_name" {
  description = "Name for the reserved static IP"
  type        = string
  default     = "moderate-dev-static-ip"
}

variable "instance_tags" {
  description = "List of tags for the instance"
  type        = list(string)
  default     = []
}

variable "boot_disk_size" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 150
}
