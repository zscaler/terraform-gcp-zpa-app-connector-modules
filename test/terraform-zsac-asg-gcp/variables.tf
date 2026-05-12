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
  description = "Number of zones to spread MIGs + autoscalers across"
  default     = 1
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3 for the test fixture."
  }
}

variable "acvm_instance_type" {
  type        = string
  description = "GCE machine type"
  default     = "n2-standard-4"
}

variable "min_size" {
  type        = number
  description = "Min replicas per zone"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Max replicas per zone"
  default     = 2
}

variable "target_tracking_metric" {
  type        = string
  description = "ASGAverageCPUUtilization | ASGAverageNetworkIn | ASGAverageNetworkOut"
  default     = "ASGAverageCPUUtilization"
}

variable "target_cpu_util_value" {
  type        = number
  description = "Target value (CPU % for CPU metric, bytes/sec/instance for network metrics)"
  default     = 50
}
