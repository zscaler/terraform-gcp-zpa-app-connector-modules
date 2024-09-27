# Zscaler Cloud Connector / GCP Network Infrastructure Module

This module has multi-purpose use and is leveraged by all other Zscaler App Connector child modules in some capacity. All network infrastructure resources pertaining to connectivity dependencies for a successful App Connector deployment in a private subnet are referenced here. Full list of resources can be found below, but in general this module will handle all VPC, Subnets, Cloud Routers, NAT Gateways, VPC peering and/or firewall dependencies to build out a resilient GCP network architecture. Most resources also have "conditional create" capabilities where, by default, they will all be created unless instructed not to with various "byo" variables. Use cases are documented in more detail in each description in variables.tf as well as the terraform.tfvars example file for all non-base deployment types (ie: ac, etc.).


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 6.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.ac_mgmt](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_network.vpc_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_router.vpc_router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.vpc_nat_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.vpc_subnet_ac](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.vpc_subnet_bastion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_network.vpc_network_selected](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_compute_router.vpc_router_selected](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_router) | data source |
| [google_compute_router_nat.vpc_nat_gateway_selected](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_router_nat) | data source |
| [google_compute_subnetwork.vpc_subnet_ac_selected](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ports"></a> [allowed\_ports](#input\_allowed\_ports) | A list of ports to permit inbound to App Connector. Default empty list means to allow all. | `list(string)` | `[]` | no |
| <a name="input_allowed_ssh_from_internal_cidr"></a> [allowed\_ssh\_from\_internal\_cidr](#input\_allowed\_ssh\_from\_internal\_cidr) | CIDR allowed to ssh the bastion host from Intranet | `list(string)` | n/a | yes |
| <a name="input_bastion_enabled"></a> [bastion\_enabled](#input\_bastion\_enabled) | Configure bastion subnet in Management VPC for SSH access to App Connector if set to true | `bool` | `false` | no |
| <a name="input_byo_natgw"></a> [byo\_natgw](#input\_byo\_natgw) | Bring your own GCP NAT Gateway App Connector | `bool` | `false` | no |
| <a name="input_byo_natgw_name"></a> [byo\_natgw\_name](#input\_byo\_natgw\_name) | User provided existing GCP NAT Gateway friendly name | `string` | `null` | no |
| <a name="input_byo_router"></a> [byo\_router](#input\_byo\_router) | Bring your own GCP Compute Router for App Connector | `bool` | `false` | no |
| <a name="input_byo_router_name"></a> [byo\_router\_name](#input\_byo\_router\_name) | User provided existing GCP Compute Router friendly name | `string` | `null` | no |
| <a name="input_byo_subnet_name"></a> [byo\_subnet\_name](#input\_byo\_subnet\_name) | User provided existing GCP Subnet friendly name | `string` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own GCP Subnets for App Connector | `bool` | `false` | no |
| <a name="input_byo_vpc"></a> [byo\_vpc](#input\_byo\_vpc) | Bring your own GCP VPC for App Connector | `bool` | `false` | no |
| <a name="input_byo_vpc_name"></a> [byo\_vpc\_name](#input\_byo\_vpc\_name) | User provided existing GCP VPC friendly name | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the module resources | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Google Cloud project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Google Cloud region | `string` | n/a | yes |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A random string for the resource name | `string` | n/a | yes |
| <a name="input_routing_mode"></a> [routing\_mode](#input\_routing\_mode) | The network-wide routing mode to use. If set to REGIONAL, this network's cloud routers will only advertise routes with subnetworks of this network in the same region as the router. If set to GLOBAL, this network's cloud routers will advertise routes with all subnetworks of this network, across regions. Possible values are: REGIONAL, GLOBAL | `string` | `"REGIONAL"` | no |
| <a name="input_subnet_ac"></a> [subnet\_ac](#input\_subnet\_ac) | A subnet IP CIDR for the App Connector in the Management VPC. This value will be ignored if byo\_mgmt\_subnet\_name is set to true | `string` | `"10.0.1.0/24"` | no |
| <a name="input_subnet_bastion"></a> [subnet\_bastion](#input\_subnet\_bastion) | A subnet IP CIDR for the greenfield/test bastion host in the Management VPC. This value will be ignored if bastion\_enabled variable is set to false | `string` | `"10.0.0.0/24"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ac_subnet"></a> [ac\_subnet](#output\_ac\_subnet) | App Connector VPC Subnetwork ID |
| <a name="output_bastion_subnet"></a> [bastion\_subnet](#output\_bastion\_subnet) | Subnet for the bastion host |
| <a name="output_vpc_nat_gateway"></a> [vpc\_nat\_gateway](#output\_vpc\_nat\_gateway) | App Connector VPC Cloud NAT Gateway ID |
| <a name="output_vpc_network"></a> [vpc\_network](#output\_vpc\_network) | App Connector VPC ID |
| <a name="output_vpc_network_name"></a> [vpc\_network\_name](#output\_vpc\_network\_name) | App Connector VPC Name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
