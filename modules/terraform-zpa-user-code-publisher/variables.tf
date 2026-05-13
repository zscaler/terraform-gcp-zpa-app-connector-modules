variable "name_prefix" {
  type        = string
  description = "Prefix for the Secret Manager secret names. The full secret id is name_prefix-resource_tag-zpa-user-code-INDEX."
}

variable "resource_tag" {
  type        = string
  description = "Random suffix appended to the secret names so multiple deployments in the same project don't collide."
}

variable "project" {
  type        = string
  description = "GCP project that hosts the App Connector VMs and the secrets."
}

variable "vm_count" {
  type        = number
  description = "Total number of App Connector VMs that will publish a code (typically `ac_count * length(zones)` for static, `min_size * length(zones)` for ASG). The module pre-creates this many secret slots."

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 100
    error_message = "vm_count must be between 1 and 100."
  }
}

variable "service_account_email" {
  type        = string
  description = "Email of the service account attached to the App Connector VMs. Granted `roles/secretmanager.secretVersionAdder` and `roles/secretmanager.secretAccessor` on each per-VM secret."
}

variable "max_wait_seconds" {
  type        = number
  description = "Per-VM time budget for the boot script to wait for /etc/issue to contain a code before giving up."
  default     = 300

  validation {
    condition     = var.max_wait_seconds >= 30 && var.max_wait_seconds <= 1800
    error_message = "max_wait_seconds must be between 30 and 1800."
  }
}
