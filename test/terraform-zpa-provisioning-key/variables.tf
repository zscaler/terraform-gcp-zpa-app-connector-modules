variable "pr_id" {
  type        = string
  description = "PR number used to prefix every resource name as `ghcip<PR_ID>`. Empty falls back to `ghcitt`. Sourced from TF_VAR_pr_id."
  default     = ""
}

variable "provisioning_key_enabled" {
  type        = bool
  description = "Whether the provisioning key is enabled"
  default     = true
}

variable "provisioning_key_association_type" {
  type        = string
  description = "Provisioning key type — only CONNECTOR_GRP is supported by this module"
  default     = "CONNECTOR_GRP"
}

variable "provisioning_key_max_usage" {
  type        = number
  description = "Maximum number of App Connectors that can enroll with this key"
  default     = 10
}
