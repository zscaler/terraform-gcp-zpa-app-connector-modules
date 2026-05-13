# Zscaler "ac_asg" deployment type

This deployment type is the **autoscaling, brownfield/production** sibling of [`ac`](../ac). It deploys ZPA App Connector instances into your existing GCP networking (BYO VPC / subnets / router / NAT) using a **per-zone Managed Instance Group + Compute Autoscaler**, growing and shrinking based on the chosen target-tracking metric. **No bastion host, no greenfield network plumbing** — production-clean.

What gets created in your project:

- 0 or 1× VPC, subnet, Cloud Router, NAT Gateway (depending on the `byo_*` toggles)
- 1× ZPA App Connector Group + 1× provisioning key (or BYO via `byo_provisioning_key`)
- 1× Compute Instance Template baked with the provisioning key in `user_data`
- **N×** Managed Instance Groups (one per zone in `var.zones` / `var.az_count`)
- **N×** Compute Autoscalers, one targeting each MIG, scaling on `var.target_tracking_metric`

## When to use this vs `base_ac_asg`

| | `base_ac_asg` (greenfield) | `ac_asg` (brownfield) |
|---|---|---|
| VPC / subnets / router / NAT | created fresh | reuse existing via `byo_*` |
| Bastion host | yes (public IP, SSH allow-list) | **no** — use your own jump host / IAP |
| Local SSH key file | written to disk | written to disk (still used for instance template metadata) |
| Intended for | PoVs, labs, demos | production / staged tenants |

Pick `ac_asg` when you already own the network and don't want this Terraform run touching it.

## How autoscaling works here

Same submodule + same surface as `base_ac_asg`. See the [`terraform-zsac-asg-gcp` README](../../modules/terraform-zsac-asg-gcp/README.md) for the metric-to-GCP mapping table.

| Variable | Default | What it does |
|---|---|---|
| `min_size` | `2` | Floor on instance count **per zone** |
| `max_size` | `4` | Ceiling on instance count **per zone** |
| `target_tracking_metric` | `ASGAverageCPUUtilization` | One of `ASGAverageCPUUtilization`, `ASGAverageNetworkIn`, `ASGAverageNetworkOut` |
| `target_cpu_util_value` | `50` | CPU % (1–100) for CPU; bytes/sec/instance for Network |
| `cooldown_period` | `60` | Seconds the autoscaler waits before sampling a fresh VM |
| `health_check_grace_period` | `300` | Seconds the MIG autohealing check waits before evaluating a new VM |

## Brownfield BYO toggles

The `byo_*` variables match `examples/ac` 1:1. Each is independently optional — set only what you bring:

| Variable | Effect when `true` | Companion |
|---|---|---|
| `byo_vpc` | Skip VPC creation | `byo_vpc_name` |
| `byo_subnets` | Skip subnet creation | `byo_subnet_name` (else `subnet_ac` defines a new CIDR) |
| `byo_router` | Skip Cloud Router creation | `byo_router_name` |
| `byo_natgw` | Skip NAT Gateway creation | `byo_natgw_name` |

> **Provisioning key reuse.** Every VM the autoscaler launches enrolls with the same static provisioning key baked into the instance template. Set `provisioning_key_max_usage` (default `100`) above `max_size × len(zones)` for headroom.

> **Connector cleanup.** Disconnected/scaled-in connectors are reaped tenant-side via the [`zpa_app_connector_assistant_schedule`](https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_app_connector_assistant_schedule) resource. Configure it once at the tenant level outside of this module.

## How to deploy

### Option 1 (guided)
```bash
./zsac up
# select: 4) ac_asg
# script will prompt you for BYO VPC / subnet / router / NAT names
```

### Option 2 (manual)
1. Edit `examples/ac_asg/terraform.tfvars`. At minimum set `project`, `region`, and any `byo_*` values that apply to your environment.
2. Authenticate to ZPA via env vars (OneAPI: `ZSCALER_CLIENT_ID`, `ZSCALER_CLIENT_SECRET`, `ZSCALER_VANITY_DOMAIN`, `ZPA_CUSTOMER_ID`; or Legacy: `ZPA_CLIENT_ID`, `ZPA_CLIENT_SECRET`, `ZPA_CUSTOMER_ID`, `ZPA_CLOUD`, `ZSCALER_USE_LEGACY_CLIENT=true`).
3. Authenticate to GCP via `gcloud auth application-default login` (recommended) or `var.credentials`.
4. Run:

```bash
cd examples/ac_asg
terraform init
terraform apply
```

## How to destroy

### Option 1 (guided)
```bash
./zsac destroy
```

### Option 2 (manual)
```bash
cd examples/ac_asg
terraform destroy
```

> `terraform destroy` removes the MIG and autoscaler. It does **not** touch resources you marked as BYO (VPC, subnet, router, NAT). Connectors that have already enrolled with the ZPA tenant remain visible (in a disconnected state) until the tenant-wide assistant schedule reaps them, or you delete them manually via the ZPA Admin Portal.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.31.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.8.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.8.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.2.0 |
| <a name="requirement_zpa"></a> [zpa](#requirement\_zpa) | ~> 4.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 7.31.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.8.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.8.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ac_asg"></a> [ac\_asg](#module\_ac\_asg) | ../../modules/terraform-zsac-asg-gcp | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/terraform-zsac-network-gcp | n/a |
| <a name="module_user_code_publisher"></a> [user\_code\_publisher](#module\_user\_code\_publisher) | ../../modules/terraform-zpa-user-code-publisher | n/a |
| <a name="module_user_code_reader"></a> [user\_code\_reader](#module\_user\_code\_reader) | ../../modules/terraform-zpa-user-code-reader | n/a |
| <a name="module_zpa_app_connector_group_legacy"></a> [zpa\_app\_connector\_group\_legacy](#module\_zpa\_app\_connector\_group\_legacy) | ../../modules/terraform-zpa-app-connector-group | n/a |
| <a name="module_zpa_app_connector_group_oauth"></a> [zpa\_app\_connector\_group\_oauth](#module\_zpa\_app\_connector\_group\_oauth) | ../../modules/terraform-zpa-app-connector-group | n/a |
| <a name="module_zpa_provisioning_key"></a> [zpa\_provisioning\_key](#module\_zpa\_provisioning\_key) | ../../modules/terraform-zpa-provisioning-key | n/a |

## Resources

| Name | Type |
|------|------|
| [google_service_account.ac_vm](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.testbed](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.user_data_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [google_compute_image.appconnector](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_compute_image.rhel_9_latest](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acvm_instance_type"></a> [acvm\_instance\_type](#input\_acvm\_instance\_type) | App Connector Instance Type | `string` | `"n2-standard-4"` | no |
| <a name="input_allowed_ports"></a> [allowed\_ports](#input\_allowed\_ports) | A list of ports to permit inbound to App Connector Service VPC. Default empty list means to allow all. | `list(string)` | `[]` | no |
| <a name="input_app_connector_group_country_code"></a> [app\_connector\_group\_country\_code](#input\_app\_connector\_group\_country\_code) | Optional: Country code of this App Connector Group. example 'US' | `string` | `"US"` | no |
| <a name="input_app_connector_group_description"></a> [app\_connector\_group\_description](#input\_app\_connector\_group\_description) | Optional: Description of the App Connector Group | `string` | `"This App Connector Group belongs to: "` | no |
| <a name="input_app_connector_group_dns_query_type"></a> [app\_connector\_group\_dns\_query\_type](#input\_app\_connector\_group\_dns\_query\_type) | Whether to enable IPv4 or IPv6, or both, for DNS resolution. | `string` | `"IPV4_IPV6"` | no |
| <a name="input_app_connector_group_enabled"></a> [app\_connector\_group\_enabled](#input\_app\_connector\_group\_enabled) | Whether this App Connector Group is enabled or not | `bool` | `true` | no |
| <a name="input_app_connector_group_latitude"></a> [app\_connector\_group\_latitude](#input\_app\_connector\_group\_latitude) | Latitude of the App Connector Group. | `string` | `"37.33874"` | no |
| <a name="input_app_connector_group_location"></a> [app\_connector\_group\_location](#input\_app\_connector\_group\_location) | Location string for the App Connector Group. | `string` | `"San Jose, CA, USA"` | no |
| <a name="input_app_connector_group_longitude"></a> [app\_connector\_group\_longitude](#input\_app\_connector\_group\_longitude) | Longitude of the App Connector Group. | `string` | `"-121.8852525"` | no |
| <a name="input_app_connector_group_override_version_profile"></a> [app\_connector\_group\_override\_version\_profile](#input\_app\_connector\_group\_override\_version\_profile) | Optional: Whether the default version profile of the App Connector Group is applied or overridden. | `bool` | `true` | no |
| <a name="input_app_connector_group_upgrade_day"></a> [app\_connector\_group\_upgrade\_day](#input\_app\_connector\_group\_upgrade\_day) | Optional: scheduled upgrade day. | `string` | `"SUNDAY"` | no |
| <a name="input_app_connector_group_upgrade_time_in_secs"></a> [app\_connector\_group\_upgrade\_time\_in\_secs](#input\_app\_connector\_group\_upgrade\_time\_in\_secs) | Optional: scheduled upgrade time-of-day, in seconds since midnight UTC. | `string` | `"66600"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Default number of zonal MIGs to create. One MIG + one autoscaler is created per zone. | `number` | `1` | no |
| <a name="input_byo_natgw"></a> [byo\_natgw](#input\_byo\_natgw) | Bring your own GCP NAT Gateway | `bool` | `false` | no |
| <a name="input_byo_natgw_name"></a> [byo\_natgw\_name](#input\_byo\_natgw\_name) | User provided existing GCP NAT Gateway friendly name | `string` | `null` | no |
| <a name="input_byo_provisioning_key"></a> [byo\_provisioning\_key](#input\_byo\_provisioning\_key) | Bring your own App Connector Provisioning Key. | `bool` | `false` | no |
| <a name="input_byo_provisioning_key_name"></a> [byo\_provisioning\_key\_name](#input\_byo\_provisioning\_key\_name) | Existing App Connector Provisioning Key name | `string` | `"provisioning-key-tf"` | no |
| <a name="input_byo_router"></a> [byo\_router](#input\_byo\_router) | Bring your own GCP Compute Router for App Connector | `bool` | `false` | no |
| <a name="input_byo_router_name"></a> [byo\_router\_name](#input\_byo\_router\_name) | User provided existing GCP Compute Router friendly name | `string` | `null` | no |
| <a name="input_byo_subnet_name"></a> [byo\_subnet\_name](#input\_byo\_subnet\_name) | User provided existing GCP Subnet friendly name | `string` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own GCP Subnets for App Connector | `bool` | `false` | no |
| <a name="input_byo_vpc"></a> [byo\_vpc](#input\_byo\_vpc) | Bring your own GCP VPC for App Connector | `bool` | `false` | no |
| <a name="input_byo_vpc_name"></a> [byo\_vpc\_name](#input\_byo\_vpc\_name) | User provided existing GCP VPC friendly name | `string` | `null` | no |
| <a name="input_cooldown_period"></a> [cooldown\_period](#input\_cooldown\_period) | Number of seconds the autoscaler waits before sampling a fresh instance after launch. | `number` | `60` | no |
| <a name="input_credentials"></a> [credentials](#input\_credentials) | Optional path to a Google Cloud service account JSON key file. Leave unset (null) to fall back to Application Default Credentials (ADC). The variable is also satisfied by the `GOOGLE_CREDENTIALS` env var read directly by the google provider. | `string` | `null` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | Time in seconds the MIG autohealing health check waits before evaluating a newly created instance. | `number` | `300` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Custom image name to be used for deploying App Connector appliances. | `string` | `""` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of App Connectors to maintain in the autoscaling group (per zone) | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of App Connectors to maintain in the autoscaling group (per zone) | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zsac"` | no |
| <a name="input_project"></a> [project](#input\_project) | Google Cloud project name | `string` | n/a | yes |
| <a name="input_provisioning_key_association_type"></a> [provisioning\_key\_association\_type](#input\_provisioning\_key\_association\_type) | Specifies the provisioning key type. | `string` | `"CONNECTOR_GRP"` | no |
| <a name="input_provisioning_key_enabled"></a> [provisioning\_key\_enabled](#input\_provisioning\_key\_enabled) | Whether the provisioning key is enabled or not. | `bool` | `true` | no |
| <a name="input_provisioning_key_max_usage"></a> [provisioning\_key\_max\_usage](#input\_provisioning\_key\_max\_usage) | Maximum enrollments per provisioning key. For autoscaling, set comfortably above max\_size * length(zones). | `number` | `100` | no |
| <a name="input_region"></a> [region](#input\_region) | Google Cloud region | `string` | n/a | yes |
| <a name="input_subnet_ac"></a> [subnet\_ac](#input\_subnet\_ac) | A subnet IP CIDR for the App Connector VPC. Only used if `byo_subnets = false`. | `string` | `"10.0.1.0/24"` | no |
| <a name="input_subnet_bastion"></a> [subnet\_bastion](#input\_subnet\_bastion) | A subnet IP CIDR for SSH allow-list reference (brownfield does NOT create a bastion) | `string` | `"10.0.0.0/24"` | no |
| <a name="input_target_cpu_util_value"></a> [target\_cpu\_util\_value](#input\_target\_cpu\_util\_value) | Target value for the autoscaling policy. CPU: percentage 1-100. Network: bytes-per-second per instance. | `number` | `50` | no |
| <a name="input_target_tracking_metric"></a> [target\_tracking\_metric](#input\_target\_tracking\_metric) | Target tracking metric for the autoscaling policy. Approved values: ASGAverageCPUUtilization, ASGAverageNetworkIn, ASGAverageNetworkOut. | `string` | `"ASGAverageCPUUtilization"` | no |
| <a name="input_tls_key_algorithm"></a> [tls\_key\_algorithm](#input\_tls\_key\_algorithm) | algorithm for tls\_private\_key resource | `string` | `"RSA"` | no |
| <a name="input_use_user_code_method"></a> [use\_user\_code\_method](#input\_use\_user\_code\_method) | OAuth2 user-code onboarding (default). Each App Connector VM publishes its /etc/issue enrollment code as a guest attribute on first boot; Terraform reads them back and passes them to the App Connector Group's user\_codes attribute, which the ZPA provider verifies. Set to false to fall back to the legacy provisioning-key flow (one shared key, baked into the VM startup script). Note for autoscaling: only resolves codes for instances present at apply time. | `bool` | `true` | no |
| <a name="input_use_zscaler_image"></a> [use\_zscaler\_image](#input\_use\_zscaler\_image) | By default, App Connector will deploy via the Zscaler Latest Image. Setting this to false will deploy the latest Red Hat Enterprise Linux 9 Image instead | `bool` | `true` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | (Optional) Availability zone names. Only required if automatic zones selection based on az\_count is undesirable | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | Google Cloud Testbed results |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
