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

variable "zone" {
  type        = string
  description = "GCP zone for the bastion VM. Provider falls back to <region>-a if null."
  default     = null
}

variable "bastion_ssh_allow_ip" {
  type        = list(string)
  description = "Allowed source CIDRs for SSH to the bastion. Default 0.0.0.0/0 for the test fixture; production deployments should restrict this."
  default     = ["0.0.0.0/0"]
}
