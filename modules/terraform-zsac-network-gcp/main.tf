################################################################################
# Create VPC Network, Subnet, Router, and NAT Gateway for App Connector 
################################################################################
resource "google_compute_network" "vpc_network" {
  count                   = var.byo_vpc == false ? 1 : 0
  name                    = "${var.name_prefix}-vpc-${var.resource_tag}"
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  project                 = var.project
}

# Or reference an existing VPC
data "google_compute_network" "vpc_network_selected" {
  count = var.byo_vpc ? 1 : 0
  name  = var.byo_vpc_name
}

################################################################################
# Create App Connector VPC Subnet
################################################################################
resource "google_compute_subnetwork" "vpc_subnet_ac" {
  count         = var.byo_subnets == false ? 1 : 0
  name          = "${var.name_prefix}-subnet-${var.resource_tag}"
  ip_cidr_range = var.subnet_ac
  network       = try(google_compute_network.vpc_network[0].self_link, data.google_compute_network.vpc_network_selected[0].self_link)
  region        = var.region
}

# Or reference an existing subnet
data "google_compute_subnetwork" "vpc_subnet_ac_selected" {
  count  = var.byo_subnets ? 1 : 0
  name   = var.byo_subnet_name
  region = var.region
}

################################################################################
# Create App Connector VPC Router
################################################################################
resource "google_compute_router" "vpc_router" {
  count   = var.byo_router == false ? 1 : 0
  name    = "${var.name_prefix}-vpc-router-${var.resource_tag}"
  network = try(google_compute_network.vpc_network[0].self_link, data.google_compute_network.vpc_network_selected[0].self_link)
}

# Or reference an existing router
data "google_compute_router" "vpc_router_selected" {
  count   = var.byo_router ? 1 : 0
  name    = var.byo_router_name
  network = var.byo_vpc_name
}

################################################################################
# Create App Connector VPC NAT Gateway
################################################################################
resource "google_compute_router_nat" "vpc_nat_gateway" {
  count                              = var.byo_natgw == false ? 1 : 0
  name                               = "${var.name_prefix}-vpc-nat-gw-${var.resource_tag}"
  router                             = try(data.google_compute_router.vpc_router_selected[0].name, google_compute_router.vpc_router[0].name)
  region                             = try(data.google_compute_router.vpc_router_selected[0].region, google_compute_router.vpc_router[0].region)
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Or reference an existing NAT Gateway
data "google_compute_router_nat" "vpc_nat_gateway_selected" {
  count  = var.byo_natgw ? 1 : 0
  name   = var.byo_natgw_name
  router = var.byo_router_name
}


################################################################################
# Create subnet for bastion jump host (if enabled) in the VPC
################################################################################
resource "google_compute_subnetwork" "vpc_subnet_bastion" {
  count         = var.bastion_enabled ? 1 : 0
  name          = "${var.name_prefix}-vpc-subnet-bastion-${var.resource_tag}"
  ip_cidr_range = var.subnet_bastion
  network       = google_compute_network.vpc_network[0].self_link
  region        = var.region
}


################################################################################
# Create pre-defined GCP Security Groups and rules for workload
################################################################################
resource "google_compute_firewall" "ac_mgmt" {
  name    = "${var.name_prefix}-fw-for-ac-mgmt-${var.resource_tag}"
  network = try(google_compute_network.vpc_network[0].self_link, data.google_compute_network.vpc_network_selected[0].self_link)
  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = var.allowed_ssh_from_internal_cidr
}
