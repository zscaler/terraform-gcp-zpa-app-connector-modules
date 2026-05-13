output "instance_group_zones" {
  description = "GCP zone assignments for the per-zone Managed Instance Groups"
  value       = google_compute_instance_group_manager.ac_instance_group_manager[*].zone
}

output "instance_group_names" {
  description = "Names of the per-zone Managed Instance Groups created by the autoscaler"
  value       = google_compute_instance_group_manager.ac_instance_group_manager[*].name
}

output "instance_group_ids" {
  description = "self_link IDs of the per-zone Managed Instance Groups"
  value       = google_compute_instance_group_manager.ac_instance_group_manager[*].instance_group
}

output "instance_template_region" {
  description = "GCP region for the App Connector instance template"
  value       = google_compute_instance_template.ac_instance_template.region
}

output "instance_template_project" {
  description = "GCP project for the App Connector instance template"
  value       = google_compute_instance_template.ac_instance_template.project
}

output "autoscaler_ids" {
  description = "self_link IDs of the per-zone Compute Autoscalers"
  value       = google_compute_autoscaler.ac_asg[*].id
}

output "autoscaler_names" {
  description = "Names of the per-zone Compute Autoscalers"
  value       = google_compute_autoscaler.ac_asg[*].name
}

output "running_instances" {
  description = "Per-zone list of VM instance self_links currently registered to each MIG (queried 60s after MIG creation to give instances time to come up). Useful for debugging and for terratest assertions that count live instances."
  value       = [for grp in data.google_compute_instance_group.ac_instance_groups : grp.instances]
}

# Flattened lists exposed for the OAuth user-code resolver, which needs to
# address each VM by name + zone. Parsed from the self_links by stripping the
# URL prefix and splitting on /. The two lists are kept parallel (same index =
# same VM).
locals {
  flat_running_instance_self_links = flatten([for grp in data.google_compute_instance_group.ac_instance_groups : grp.instances])
}

output "running_instance_names" {
  description = "Names of every VM currently registered across all MIGs (parallel list to running_instance_zones). Pass to the user-code resolver as instance_names."
  value       = [for sl in local.flat_running_instance_self_links : reverse(split("/", sl))[0]]
}

output "running_instance_zones" {
  description = "Zones for every VM currently registered across all MIGs (parallel list to running_instance_names). Pass to the user-code resolver as instance_zones."
  value       = [for sl in local.flat_running_instance_self_links : reverse(split("/", sl))[2]]
}
