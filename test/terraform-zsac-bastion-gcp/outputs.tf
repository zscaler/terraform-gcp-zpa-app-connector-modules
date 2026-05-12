################################################################################
# Passthrough outputs
################################################################################
output "public_ip" {
  description = "Bastion public IP returned by the module"
  value       = module.bastion.public_ip
}

output "vpc_network" {
  description = "VPC the bastion is attached to"
  value       = module.network.vpc_network
}

################################################################################
# Validation outputs
################################################################################
output "public_ip_valid" {
  description = "Validation that the bastion public IP is non-empty"
  value       = length(module.bastion.public_ip) > 0 ? "true" : "false"
}

output "vpc_network_valid" {
  description = "Validation that the upstream VPC self_link is non-empty"
  value       = length(module.network.vpc_network) > 0 ? "true" : "false"
}
