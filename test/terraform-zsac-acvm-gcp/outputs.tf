################################################################################
# Passthrough outputs
################################################################################
output "instance_group_zones" {
  description = "Zones the per-zone MIGs were created in"
  value       = module.ac_vm.instance_group_zones
}

output "instance_group_names" {
  description = "Names of the per-zone MIGs"
  value       = module.ac_vm.instance_group_names
}

output "ac_private_ip" {
  description = "Internal IPs of every App Connector VM"
  value       = module.ac_vm.ac_private_ip
}

################################################################################
# Validation outputs
################################################################################
output "instance_group_count_correct" {
  description = "Validation that one MIG was created per zone"
  value       = length(module.ac_vm.instance_group_names) == var.az_count ? "true" : "false"
}

output "ac_vm_count_correct" {
  description = "Validation that ac_count * az_count VMs were spawned"
  value       = length(module.ac_vm.ac_private_ip) == var.ac_count * var.az_count ? "true" : "false"
}

output "instance_template_project_correct" {
  description = "Validation that the instance template was created in the requested project"
  value       = module.ac_vm.instance_template_project == var.project ? "true" : "false"
}
