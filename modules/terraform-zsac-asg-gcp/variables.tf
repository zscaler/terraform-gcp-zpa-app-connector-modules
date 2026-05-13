variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the App Connector ASG module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the App Connector ASG module resources"
  default     = null
}

variable "user_data" {
  type        = string
  description = "Cloud Init / startup-script data executed by every instance launched from the template"
}

variable "project" {
  type        = string
  description = "Google Cloud project name"
}

variable "region" {
  type        = string
  description = "Google Cloud region"
}

variable "zones" {
  type        = list(string)
  description = "Availability zone names. One Managed Instance Group + one Autoscaler is created per zone."
}

variable "acvm_instance_type" {
  type        = string
  description = "App Connector Instance Type"
  default     = "n2-standard-4"
  validation {
    condition = (
      var.acvm_instance_type == "n2-standard-4" ||
      var.acvm_instance_type == "n2-highcpu-4" ||
      var.acvm_instance_type == "n1-standard-4" ||
      var.acvm_instance_type == "n1-highcpu-4" ||
      var.acvm_instance_type == "n2-standard-8" ||
      var.acvm_instance_type == "n2-highcpu-8" ||
      var.acvm_instance_type == "n1-standard-8" ||
      var.acvm_instance_type == "n1-highcpu-8"
    )
    error_message = "Input acvm_instance_type must be set to an approved vm instance type."
  }
}

variable "ssh_key" {
  type        = string
  description = "A public key uploaded to the App Connector instances"
}

variable "acvm_vpc_subnetwork" {
  type        = string
  description = "VPC subnetwork the App Connector instances are launched in"
}

variable "image_name" {
  type        = string
  description = "Custom image name to be used for deploying App Connector appliances. Ideally all VMs should be on the same image as templates always pull the latest from Google Marketplace."
  default     = ""
}

variable "disk_size" {
  type        = string
  description = "The size of the boot disk in gigabytes. If not specified, it will inherit the size of its base image"
  default     = "64"
}

################################################################################
# Autoscaling controls (mirror the AWS terraform-zsac-asg-aws module surface)
################################################################################

variable "min_size" {
  type        = number
  description = "Minimum number of App Connectors to maintain in the autoscaling group (per zone)"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of App Connectors to maintain in the autoscaling group (per zone)"
  default     = 4
}

variable "target_tracking_metric" {
  type        = string
  description = "Target tracking metric for the autoscaling policy. Names mirror AWS predefined metric types so callers can switch clouds without renaming. App Connector recommends ASGAverageCPUUtilization."
  default     = "ASGAverageCPUUtilization"
  validation {
    condition = (
      var.target_tracking_metric == "ASGAverageCPUUtilization" ||
      var.target_tracking_metric == "ASGAverageNetworkIn" ||
      var.target_tracking_metric == "ASGAverageNetworkOut"
    )
    error_message = "Input target_tracking_metric must be one of: ASGAverageCPUUtilization, ASGAverageNetworkIn, ASGAverageNetworkOut."
  }
}

variable "target_cpu_util_value" {
  type        = number
  description = "Target value for the autoscaling policy. For ASGAverageCPUUtilization this is interpreted as a CPU utilization percentage (1-100, divided by 100 internally because GCP wants a 0.0-1.0 fraction). For ASGAverageNetworkIn/Out this is interpreted as bytes-per-second per instance."
  default     = 50
}

variable "cooldown_period" {
  type        = number
  description = "The number of seconds the autoscaler waits before it starts collecting information from a new instance. Prevents the autoscaler from acting on usage data while the instance is still initializing."
  default     = 60
}

variable "health_check_grace_period" {
  type        = number
  description = "Time in seconds the autohealing health check waits before checking a newly created instance. Mirrors AWS health_check_grace_period semantics."
  default     = 300
}

################################################################################
# MIG update policy (kept identical to terraform-zsac-acvm-gcp for consistency)
################################################################################

variable "update_policy_type" {
  type        = string
  description = "The type of update process. PROACTIVE drives instances to their target version actively; OPPORTUNISTIC only updates as part of other actions."
  default     = "OPPORTUNISTIC"
  validation {
    condition = (
      var.update_policy_type == "PROACTIVE" ||
      var.update_policy_type == "OPPORTUNISTIC"
    )
    error_message = "Input update_policy_type must be set to an approved value."
  }
}

variable "update_policy_replacement_method" {
  type        = string
  description = "The instance replacement method for the MIG. SUBSTITUTE replaces VMs with new ones with random names; RECREATE preserves names but requires max_unavailable_fixed > 0."
  default     = "SUBSTITUTE"
  validation {
    condition = (
      var.update_policy_replacement_method == "RECREATE" ||
      var.update_policy_replacement_method == "SUBSTITUTE"
    )
    error_message = "Input update_policy_replacement_method must be set to an approved value."
  }
}

variable "update_policy_max_surge_fixed" {
  type        = number
  description = "Maximum number of instances created above the specified target_size during the update process."
  default     = 1
}

variable "update_max_unavailable_fixed" {
  type        = number
  description = "Maximum number of instances that can be unavailable during the update process."
  default     = 1
}
