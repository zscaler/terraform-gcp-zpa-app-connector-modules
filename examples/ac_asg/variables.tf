variable "name_prefix" {
  type        = string
  description = "The name prefix for all your resources"
  default     = "zsac"
  validation {
    condition     = length(var.name_prefix) <= 12
    error_message = "Variable name_prefix must be 12 or less characters."
  }
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "Variable name_prefix using invalid characters."
  }
}

variable "credentials" {
  type        = string
  description = "Optional path to a Google Cloud service account JSON key file. Leave unset (null) to fall back to Application Default Credentials (ADC). The variable is also satisfied by the `GOOGLE_CREDENTIALS` env var read directly by the google provider."
  default     = null
}

variable "project" {
  type        = string
  description = "Google Cloud project name"
}

variable "region" {
  type        = string
  description = "Google Cloud region"
}

variable "allowed_ports" {
  description = "A list of ports to permit inbound to App Connector Service VPC. Default empty list means to allow all."
  default     = []
  type        = list(string)
}

variable "subnet_bastion" {
  type        = string
  description = "A subnet IP CIDR for SSH allow-list reference (brownfield does NOT create a bastion)"
  default     = "10.0.0.0/24"
}

variable "subnet_ac" {
  type        = string
  description = "A subnet IP CIDR for the App Connector VPC. Only used if `byo_subnets = false`."
  default     = "10.0.1.0/24"
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

variable "tls_key_algorithm" {
  type        = string
  description = "algorithm for tls_private_key resource"
  default     = "RSA"
}

variable "az_count" {
  type        = number
  description = "Default number of zonal MIGs to create. One MIG + one autoscaler is created per zone."
  default     = 1
  validation {
    condition = (
      (var.az_count >= 1 && var.az_count <= 3)
    )
    error_message = "Input az_count must be set to a single value between 1 and 3."
  }
}

variable "zones" {
  type        = list(string)
  description = "(Optional) Availability zone names. Only required if automatic zones selection based on az_count is undesirable"
  default     = []
}

variable "image_name" {
  type        = string
  description = "Custom image name to be used for deploying App Connector appliances."
  default     = ""
}

variable "use_zscaler_image" {
  default     = true
  type        = bool
  description = "By default, App Connector will deploy via the Zscaler Latest Image. Setting this to false will deploy the latest Red Hat Enterprise Linux 9 Image instead"
}

variable "use_user_code_method" {
  type        = bool
  description = "OAuth2 user-code onboarding (default). Each App Connector VM publishes its /etc/issue enrollment code as a guest attribute on first boot; Terraform reads them back and passes them to the App Connector Group's user_codes attribute, which the ZPA provider verifies. Set to false to fall back to the legacy provisioning-key flow (one shared key, baked into the VM startup script). Note for autoscaling: only resolves codes for instances present at apply time."
  default     = true
}


################################################################################
# Autoscaling controls
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
  description = "Target tracking metric for the autoscaling policy. Approved values: ASGAverageCPUUtilization, ASGAverageNetworkIn, ASGAverageNetworkOut."
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
  description = "Target value for the autoscaling policy. CPU: percentage 1-100. Network: bytes-per-second per instance."
  default     = 50
}

variable "cooldown_period" {
  type        = number
  description = "Number of seconds the autoscaler waits before sampling a fresh instance after launch."
  default     = 60
}

variable "health_check_grace_period" {
  type        = number
  description = "Time in seconds the MIG autohealing health check waits before evaluating a newly created instance."
  default     = 300
}


################################################################################
# ZPA App Connector Group + Provisioning Key
################################################################################

variable "byo_provisioning_key" {
  type        = bool
  description = "Bring your own App Connector Provisioning Key."
  default     = false
}

variable "byo_provisioning_key_name" {
  type        = string
  description = "Existing App Connector Provisioning Key name"
  default     = "provisioning-key-tf"
}

variable "app_connector_group_description" {
  type        = string
  description = "Optional: Description of the App Connector Group"
  default     = "This App Connector Group belongs to: "
}

variable "app_connector_group_enabled" {
  type        = bool
  description = "Whether this App Connector Group is enabled or not"
  default     = true
}

variable "app_connector_group_country_code" {
  type        = string
  description = "Optional: Country code of this App Connector Group. example 'US'"
  default     = "US"
}

variable "app_connector_group_latitude" {
  type        = string
  description = "Latitude of the App Connector Group."
  default     = "37.33874"
}

variable "app_connector_group_longitude" {
  type        = string
  description = "Longitude of the App Connector Group."
  default     = "-121.8852525"
}

variable "app_connector_group_location" {
  type        = string
  description = "Location string for the App Connector Group."
  default     = "San Jose, CA, USA"
}

variable "app_connector_group_upgrade_day" {
  type        = string
  description = "Optional: scheduled upgrade day."
  default     = "SUNDAY"
}

variable "app_connector_group_upgrade_time_in_secs" {
  type        = string
  description = "Optional: scheduled upgrade time-of-day, in seconds since midnight UTC."
  default     = "66600"
}

variable "app_connector_group_override_version_profile" {
  type        = bool
  description = "Optional: Whether the default version profile of the App Connector Group is applied or overridden."
  default     = true
}

variable "app_connector_group_dns_query_type" {
  type        = string
  description = "Whether to enable IPv4 or IPv6, or both, for DNS resolution."
  default     = "IPV4_IPV6"
  validation {
    condition = (
      var.app_connector_group_dns_query_type == "IPV4_IPV6" ||
      var.app_connector_group_dns_query_type == "IPV4" ||
      var.app_connector_group_dns_query_type == "IPV6"
    )
    error_message = "Input app_connector_group_dns_query_type must be set to an approved value."
  }
}

variable "provisioning_key_enabled" {
  type        = bool
  description = "Whether the provisioning key is enabled or not."
  default     = true
}

variable "provisioning_key_association_type" {
  type        = string
  description = "Specifies the provisioning key type."
  default     = "CONNECTOR_GRP"
  validation {
    condition = (
      var.provisioning_key_association_type == "CONNECTOR_GRP"
    )
    error_message = "Input provisioning_key_association_type must be set to an approved value."
  }
}

variable "provisioning_key_max_usage" {
  type        = number
  description = "Maximum enrollments per provisioning key. For autoscaling, set comfortably above max_size * length(zones)."
  default     = 100
}


################################################################################
# Brownfield BYO toggles (mirrors examples/ac/variables.tf)
################################################################################

variable "byo_vpc" {
  type        = bool
  description = "Bring your own GCP VPC for App Connector"
  default     = false
}

variable "byo_vpc_name" {
  type        = string
  description = "User provided existing GCP VPC friendly name"
  default     = null
}

variable "byo_subnets" {
  type        = bool
  description = "Bring your own GCP Subnets for App Connector"
  default     = false
}

variable "byo_subnet_name" {
  type        = string
  description = "User provided existing GCP Subnet friendly name"
  default     = null
}

variable "byo_router" {
  type        = bool
  description = "Bring your own GCP Compute Router for App Connector"
  default     = false
}

variable "byo_router_name" {
  type        = string
  description = "User provided existing GCP Compute Router friendly name"
  default     = null
}

variable "byo_natgw" {
  type        = bool
  description = "Bring your own GCP NAT Gateway"
  default     = false
}

variable "byo_natgw_name" {
  type        = string
  description = "User provided existing GCP NAT Gateway friendly name"
  default     = null
}
