variable "pr_id" {
  type        = string
  description = "PR number used to prefix every resource name as `ghcip<PR_ID>`. Empty falls back to `ghcitt`. Sourced from TF_VAR_pr_id."
  default     = ""
}

variable "project" {
  type        = string
  description = "GCP project ID. Set via TF_VAR_project (Makefile reads $PROJECT_ID)."
}

variable "region" {
  type        = string
  description = "GCP region. Set via TF_VAR_region (Makefile defaults REGION to us-central1)."
  default     = "us-central1"
}

variable "subnet_bastion" {
  type        = string
  description = "CIDR for the greenfield bastion subnet"
  default     = "10.0.0.0/24"
}

variable "subnet_ac" {
  type        = string
  description = "CIDR for the App Connector subnet"
  default     = "10.0.1.0/24"
}

variable "bastion_enabled" {
  type        = bool
  description = "Whether the bastion subnet is created"
  default     = true
}

variable "allowed_ports" {
  type        = list(string)
  description = "Ports allowed inbound to the App Connector subnet. Empty = all."
  default     = []
}

variable "routing_mode" {
  type        = string
  description = "GCP VPC routing mode (REGIONAL or GLOBAL)"
  default     = "REGIONAL"
}
