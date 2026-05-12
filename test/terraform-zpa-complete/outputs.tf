################################################################################
# Passthrough outputs from each module the e2e test composes
################################################################################
output "vpc_network_name" {
  description = "Name of the VPC network created by the network module — passthrough for terratest assertions."
  value       = module.network.vpc_network_name
}

output "ac_subnet" {
  description = "Self-link of the App Connector subnet — passthrough for terratest assertions."
  value       = module.network.ac_subnet
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host — passthrough; terratest asserts non-empty."
  value       = module.bastion.public_ip
}

output "app_connector_group_id" {
  description = "ID of the ZPA App Connector Group created — passthrough; terratest asserts non-empty."
  value       = module.zpa_app_connector_group.app_connector_group_id
}

output "provisioning_key" {
  description = "ZPA provisioning key value — passthrough; sensitive. Terratest only checks length, never logs the value."
  value       = module.zpa_provisioning_key.provisioning_key
  sensitive   = true
}

output "ac_private_ip" {
  description = "Private IPs of the App Connector VMs — passthrough; terratest asserts the count matches ac_count * az_count."
  value       = module.ac_vm.ac_private_ip
}

output "instance_group_names" {
  description = "Names of the per-zone Managed Instance Groups — passthrough; terratest asserts the count matches az_count."
  value       = module.ac_vm.instance_group_names
}

################################################################################
# Validation outputs (boolean strings consumed by the Go assertions)
################################################################################
output "vpc_network_valid" {
  description = "Boolean string ('true'/'false'): VPC network self_link is non-empty. Consumed by terratest assert.Equal."
  value       = length(module.network.vpc_network) > 0 ? "true" : "false"
}

output "bastion_public_ip_valid" {
  description = "Boolean string ('true'/'false'): bastion public IP is non-empty."
  value       = length(module.bastion.public_ip) > 0 ? "true" : "false"
}

output "app_connector_group_id_valid" {
  description = "Boolean string ('true'/'false'): ZPA App Connector Group ID is non-empty."
  value       = length(module.zpa_app_connector_group.app_connector_group_id) > 0 ? "true" : "false"
}

output "provisioning_key_valid" {
  description = "Boolean string ('true'/'false'): ZPA provisioning key value is non-empty."
  value       = length(module.zpa_provisioning_key.provisioning_key) > 0 ? "true" : "false"
}

output "instance_group_count_correct" {
  description = "Boolean string ('true'/'false'): number of MIGs equals var.az_count."
  value       = length(module.ac_vm.instance_group_names) == var.az_count ? "true" : "false"
}

output "ac_vm_count_correct" {
  description = "Boolean string ('true'/'false'): total App Connector VMs equals ac_count * az_count."
  value       = length(module.ac_vm.ac_private_ip) == var.ac_count * var.az_count ? "true" : "false"
}
