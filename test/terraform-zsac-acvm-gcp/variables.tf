variable "pr_id" {
  type        = string
  description = "PR number used to prefix every resource name as `ghcip<PR_ID>`. Empty falls back to `ghcitt`. Sourced from TF_VAR_pr_id."
  default     = ""
}

variable "project" {
  type        = string
  description = "GCP project ID. Set via TF_VAR_project."
}

variable "region" {
  type        = string
  description = "GCP region. Set via TF_VAR_region."
  default     = "us-central1"
}

variable "az_count" {
  type        = number
  description = "Number of zones to spread MIGs across"
  default     = 1
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3 for the test fixture."
  }
}

variable "ac_count" {
  type        = number
  description = "Number of App Connector VMs per zone"
  default     = 1
}

variable "acvm_instance_type" {
  type        = string
  description = "GCE machine type. Test fixture uses the smallest supported size."
  default     = "n2-standard-4"
}
