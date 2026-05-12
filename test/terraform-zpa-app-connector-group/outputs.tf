################################################################################
# Passthrough outputs from the module under test
################################################################################
output "app_connector_group_id" {
  description = "ZPA App Connector Group ID returned by the module"
  value       = module.app_connector_group.app_connector_group_id
}

################################################################################
# Validation outputs (boolean strings consumed by the Go assertions)
################################################################################
output "app_connector_group_id_valid" {
  description = "Validation that the App Connector Group ID is a non-empty string"
  value       = length(module.app_connector_group.app_connector_group_id) > 0 ? "true" : "false"
}
