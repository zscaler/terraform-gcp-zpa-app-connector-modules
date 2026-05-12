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
}

variable "ac_count" {
  type        = number
  description = "Number of App Connector VMs per zone"
  default     = 1
}

variable "acvm_instance_type" {
  type        = string
  description = "GCE machine type"
  default     = "n2-standard-4"
}

variable "subnet_bastion" {
  type        = string
  description = "CIDR for the bastion subnet"
  default     = "10.0.0.0/24"
}

variable "subnet_ac" {
  type        = string
  description = "CIDR for the App Connector subnet"
  default     = "10.0.1.0/24"
}

variable "bastion_ssh_allow_ip" {
  type        = list(string)
  description = "Allowed source CIDRs for SSH to the bastion. Default 0.0.0.0/0 for the test fixture."
  default     = ["0.0.0.0/0"]
}

variable "allowed_ports" {
  type        = list(string)
  description = "Ports allowed inbound to the App Connector subnet"
  default     = []
}
