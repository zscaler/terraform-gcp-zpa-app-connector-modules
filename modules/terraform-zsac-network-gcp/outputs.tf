output "vpc_network" {
  description = "App Connector VPC ID"
  value       = try(google_compute_network.vpc_network[0].self_link, data.google_compute_network.vpc_network_selected[0].self_link)
}

output "vpc_network_name" {
  description = "App Connector VPC Name"
  value       = try(google_compute_network.vpc_network[0].name, data.google_compute_network.vpc_network_selected[0].name)
}

output "ac_subnet" {
  description = "App Connector VPC Subnetwork ID"
  value       = try(google_compute_subnetwork.vpc_subnet_ac[0].self_link, data.google_compute_subnetwork.vpc_subnet_ac_selected[0].self_link)
}

output "bastion_subnet" {
  description = "Subnet for the bastion host"
  value       = google_compute_subnetwork.vpc_subnet_bastion[*].self_link
}

output "vpc_nat_gateway" {
  description = "App Connector VPC Cloud NAT Gateway ID"
  value       = try(google_compute_router_nat.vpc_nat_gateway[0].id, data.google_compute_router_nat.vpc_nat_gateway_selected[0].id, null)
}
