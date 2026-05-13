output "user_codes" {
  description = "OAuth user codes resolved from the publisher's Secret Manager slots, in the same order as `var.secret_ids`. Pass directly to `zpa_app_connector_group.user_codes`. Apply errors loudly with 404 if any slot has not been published to within the publish_wait_seconds budget."
  value       = data.google_secret_manager_secret_version.user_code[*].secret_data
  sensitive   = true
}
