################################################################################
# Create Service Account to be assigned to bastion workload
################################################################################
resource "google_service_account" "service_account_bastion" {
  account_id   = "${var.name_prefix}-jump-sa-${var.resource_tag}"
  display_name = "${var.name_prefix}-jump-sa-${var.resource_tag}"
}

################################################################################
# Create Bastion instance host with automatic public IP association
################################################################################
resource "google_compute_instance" "bastion" {
  name         = "${var.name_prefix}-bastion-host-${var.resource_tag}"
  machine_type = var.instance_type
  zone         = var.zone
  network_interface {
    subnetwork = var.public_subnet
    access_config {
      #Ephemeral IP
    }
  }
  metadata = {
    ssh-keys = "ubuntu:${var.ssh_key}"
  }
  metadata_startup_script = "sudo apt install net-tools"
  boot_disk {
    initialize_params {
      image = var.workload_image_name
      type  = "pd-ssd"
      size  = "10"
    }
  }
  service_account {
    email  = google_service_account.service_account_bastion.email
    scopes = ["cloud-platform"]
  }
}


################################################################################
# Split user-supplied source ranges into IPv4 vs IPv6 buckets.
#
# GCP firewall rules cannot mix IPv4 and IPv6 source_ranges in a single rule
# (see https://cloud.google.com/firewall/docs/using-firewalls), so we split
# the user-supplied list and create two rules — one per address family.
# Detection is by colon character: IPv6 CIDRs always contain ":", IPv4 never.
################################################################################
locals {
  bastion_ssh_allow_ip_v4 = [for c in var.bastion_ssh_allow_ip : c if !strcontains(c, ":")]
  bastion_ssh_allow_ip_v6 = [for c in var.bastion_ssh_allow_ip : c if strcontains(c, ":")]
}


################################################################################
# Create pre-defined GCP Firewall rules for Bastion (IPv4)
################################################################################
resource "google_compute_firewall" "ssh_internet_ingress_v4" {
  count       = length(local.bastion_ssh_allow_ip_v4) > 0 ? 1 : 0
  name        = "${var.name_prefix}-fw-ssh-for-internet-v4-${var.resource_tag}"
  description = "Permit SSH access to bastion host from approved IPv4 source ranges"
  network     = var.vpc_network
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges           = local.bastion_ssh_allow_ip_v4
  target_service_accounts = [google_service_account.service_account_bastion.email]
}


################################################################################
# Create pre-defined GCP Firewall rules for Bastion (IPv6)
################################################################################
resource "google_compute_firewall" "ssh_internet_ingress_v6" {
  count       = length(local.bastion_ssh_allow_ip_v6) > 0 ? 1 : 0
  name        = "${var.name_prefix}-fw-ssh-for-internet-v6-${var.resource_tag}"
  description = "Permit SSH access to bastion host from approved IPv6 source ranges"
  network     = var.vpc_network
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges           = local.bastion_ssh_allow_ip_v6
  target_service_accounts = [google_service_account.service_account_bastion.email]
}
