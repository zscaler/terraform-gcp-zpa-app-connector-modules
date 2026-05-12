################################################################################
# Passthrough outputs
################################################################################
output "vpc_network" {
  description = "Self link of the VPC the module created"
  value       = module.network.vpc_network
}

output "vpc_network_name" {
  description = "Name of the VPC the module created"
  value       = module.network.vpc_network_name
}

output "ac_subnet" {
  description = "Self link of the App Connector subnet"
  value       = module.network.ac_subnet
}

output "bastion_subnet" {
  description = "Self link(s) of the bastion subnet"
  value       = module.network.bastion_subnet
}

output "vpc_nat_gateway" {
  description = "NAT Gateway ID"
  value       = module.network.vpc_nat_gateway
}

################################################################################
# Validation outputs
################################################################################
output "vpc_network_valid" {
  description = "Validation that the VPC self_link is non-empty"
  value       = length(module.network.vpc_network) > 0 ? "true" : "false"
}

output "ac_subnet_valid" {
  description = "Validation that the App Connector subnet self_link is non-empty"
  value       = length(module.network.ac_subnet) > 0 ? "true" : "false"
}

output "bastion_subnet_count_correct" {
  description = "Validation that exactly one bastion subnet was created when bastion_enabled = true"
  value       = (var.bastion_enabled ? length(module.network.bastion_subnet) == 1 : length(module.network.bastion_subnet) == 0) ? "true" : "false"
}

output "nat_gateway_valid" {
  description = "Validation that the Cloud NAT gateway ID is non-empty (greenfield path)"
  value       = module.network.vpc_nat_gateway != null ? "true" : "false"
}
