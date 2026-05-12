################################################################################
# Passthrough outputs
################################################################################
output "instance_group_zones" {
  description = "Zones the per-zone MIGs were created in"
  value       = module.ac_asg.instance_group_zones
}

output "instance_group_names" {
  description = "Names of the per-zone MIGs"
  value       = module.ac_asg.instance_group_names
}

output "autoscaler_names" {
  description = "Names of the per-zone autoscalers"
  value       = module.ac_asg.autoscaler_names
}

output "autoscaler_ids" {
  description = "IDs of the per-zone autoscalers"
  value       = module.ac_asg.autoscaler_ids
}

################################################################################
# Validation outputs
################################################################################
output "instance_group_count_correct" {
  description = "Validation that one MIG was created per zone"
  value       = length(module.ac_asg.instance_group_names) == var.az_count ? "true" : "false"
}

output "autoscaler_count_correct" {
  description = "Validation that one autoscaler was created per MIG"
  value       = length(module.ac_asg.autoscaler_names) == var.az_count ? "true" : "false"
}

output "instance_template_project_correct" {
  description = "Validation that the instance template was created in the requested project"
  value       = module.ac_asg.instance_template_project == var.project ? "true" : "false"
}
