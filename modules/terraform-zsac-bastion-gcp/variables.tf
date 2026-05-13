variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the bastion module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all bastion module resources"
  default     = null
}

variable "public_subnet" {
  type        = string
  description = "The public subnet where the bastion host has to be attached"
}

variable "instance_type" {
  type        = string
  description = "The bastion host instance type"
  default     = "e2-micro"
}

variable "ssh_key" {
  type        = string
  description = "A public key uploaded to the bastion instance"
}

variable "zone" {
  type        = string
  description = "The zone that the machine should be created in. If it is not provided, the provider zone is used"
  default     = null
}

variable "workload_image_name" {
  type        = string
  description = "Custom image name to be used for deploying bastion/workload appliances"
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "bastion_ssh_allow_ip" {
  type        = list(string)
  description = "CIDR blocks of trusted networks for bastion host ssh access from Internet. Both IPv4 (e.g. 1.2.3.4/32) and IPv6 (e.g. 2001:db8::1/128) are accepted; the module splits them into two firewall rules because GCP does not allow mixed-family source_ranges in a single rule. NOTE: IPv6 host addresses MUST use /128, not /32 — /32 is only valid for IPv4."
  default     = ["0.0.0.0/0"]
  validation {
    # An IPv6 CIDR contains ":". When the mask is "/32" the entry is malformed
    # (the IPv6 host mask is /128). Catch this at plan time rather than at the
    # GCP API level where the error message is generic.
    condition = alltrue([
      for c in var.bastion_ssh_allow_ip :
      !(strcontains(c, ":") && endswith(c, "/32"))
    ])
    error_message = "bastion_ssh_allow_ip contains an IPv6 address with a /32 mask. Use /128 for IPv6 host addresses."
  }
}

variable "vpc_network" {
  type        = string
  description = "Bastion VPC network"
}
