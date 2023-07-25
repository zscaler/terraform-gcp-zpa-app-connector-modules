variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A random string for the resource name"
}

variable "project" {
  type        = string
  description = "Google Cloud project name"
}

variable "region" {
  type        = string
  description = "Google Cloud region"
}

variable "subnet_bastion" {
  type        = string
  description = "A subnet IP CIDR for the greenfield/test bastion host in the Management VPC. This value will be ignored if bastion_enabled variable is set to false"
  default     = "10.0.0.0/24"
}

variable "subnet_ac" {
  type        = string
  description = "A subnet IP CIDR for the App Connector in the Management VPC. This value will be ignored if byo_mgmt_subnet_name is set to true"
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_from_internal_cidr" {
  type        = list(string)
  description = "CIDR allowed to ssh the bastion host from Intranet"
}

variable "allowed_ports" {
  description = "A list of ports to permit inbound to App Connector. Default empty list means to allow all."
  default     = []
  type        = list(string)
}

variable "bastion_enabled" {
  type        = bool
  default     = false
  description = "Configure bastion subnet in Management VPC for SSH access to App Connector if set to true"
}

variable "routing_mode" {
  type        = string
  default     = "REGIONAL"
  description = "The network-wide routing mode to use. If set to REGIONAL, this network's cloud routers will only advertise routes with subnetworks of this network in the same region as the router. If set to GLOBAL, this network's cloud routers will advertise routes with all subnetworks of this network, across regions. Possible values are: REGIONAL, GLOBAL"
}


# BYO (Bring-your-own) variables list

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
  description = "Bring your own GCP NAT Gateway App Connector"
  default     = false
}

variable "byo_natgw_name" {
  type        = string
  description = "User provided existing GCP NAT Gateway friendly name"
  default     = null
}
