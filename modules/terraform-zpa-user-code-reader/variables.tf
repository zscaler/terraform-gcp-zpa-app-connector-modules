variable "project" {
  type        = string
  description = "GCP project that owns the secrets (must match the publisher's project)."
}

variable "secret_ids" {
  type        = list(string)
  description = "List of Secret Manager secret ids to read. Pass `module.user_code_publisher.secret_ids`."
}

variable "secrets_ready" {
  type        = any
  description = "Sentinel signalling 'publisher secrets and IAM exist'. Pass `module.user_code_publisher.secrets_ready`. Used as a trigger so the time_sleep doesn't start before secrets are real."
  default     = null
}

variable "vms_ready" {
  type        = any
  description = "Sentinel signalling 'VMs are created and discoverable'. Pass an output that depends on the VMs (e.g. `module.ac_vm.ac_instance_names`). Used as a trigger so the time_sleep doesn't start before any VM exists to publish codes."
  default     = null
}

variable "publish_wait_seconds" {
  type        = number
  description = "How long the time_sleep waits (after VMs exist + secrets exist) before reading versions back. Should cover worst-case VM boot + daemon-startup + /etc/issue-write + gcloud-publish. Default 240s."
  default     = 240

  validation {
    condition     = var.publish_wait_seconds >= 30 && var.publish_wait_seconds <= 1800
    error_message = "publish_wait_seconds must be between 30 and 1800."
  }
}
