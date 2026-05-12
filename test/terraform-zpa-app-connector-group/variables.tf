variable "pr_id" {
  type        = string
  description = "PR number used to prefix every resource name as `ghcip<PR_ID>`. Empty falls back to `ghcitt` (release / scheduled run). Sourced from the TF_VAR_pr_id env var which CI sets to the value of the workflow's `pr-id` input."
  default     = ""
}

variable "app_connector_group_enabled" {
  type        = bool
  description = "Whether the App Connector Group created by this test fixture is enabled"
  default     = true
}

variable "app_connector_group_latitude" {
  type        = string
  description = "Latitude of the App Connector Group"
  default     = "37.33874"
}

variable "app_connector_group_longitude" {
  type        = string
  description = "Longitude of the App Connector Group"
  default     = "-121.8852525"
}

variable "app_connector_group_location" {
  type        = string
  description = "City, State, Country location string"
  default     = "San Jose, CA, USA"
}

variable "app_connector_group_country_code" {
  type        = string
  description = "ISO country code for the App Connector Group"
  default     = "US"
}
