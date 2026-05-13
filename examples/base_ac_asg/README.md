# Zscaler "base_ac_asg" deployment type

This deployment type is the **autoscaling, greenfield/PoV/lab** sibling of [`base_ac`](../base_ac). It deploys a fully functioning sandbox in a brand-new VPC with a publicly accessible bastion host, and replaces the fixed-size App Connector instance group with a **per-zone Managed Instance Group + Compute Autoscaler** that grows and shrinks based on a target-tracking metric.

What gets created:

- 1× new "Management" VPC with 1× AC subnet and 1× bastion subnet
- 1× Cloud Router + NAT Gateway
- 1× Bastion Host with a dynamic public IP
- A locally-generated SSH key pair `.pem` for jump access
- 1× ZPA App Connector Group + 1× provisioning key (or BYO via `byo_provisioning_key`)
- 1× Compute Instance Template baked with the provisioning key in `user_data`
- **N×** Managed Instance Groups (one per zone in `var.zones` / `var.az_count`)
- **N×** Compute Autoscalers, one targeting each MIG, scaling on the metric chosen via `var.target_tracking_metric`

## How autoscaling works here

This example wires the [`terraform-zsac-asg-gcp`](../../modules/terraform-zsac-asg-gcp) submodule, which mirrors the surface of the AWS [`terraform-zsac-asg-aws`](https://github.com/zscaler/terraform-aws-zpa-app-connector-modules/tree/main/modules/terraform-zsac-asg-aws) module so deployments are portable across clouds.

| Variable | Default | What it does |
|---|---|---|
| `min_size` | `2` | Floor on instance count **per zone** |
| `max_size` | `4` | Ceiling on instance count **per zone** |
| `target_tracking_metric` | `ASGAverageCPUUtilization` | One of `ASGAverageCPUUtilization`, `ASGAverageNetworkIn`, `ASGAverageNetworkOut` |
| `target_cpu_util_value` | `50` | Target value: CPU % (1–100) for CPU, bytes/sec/instance for Network |
| `cooldown_period` | `60` | Seconds the autoscaler waits before sampling a freshly-launched VM |
| `health_check_grace_period` | `300` | Seconds the MIG autohealing check waits before evaluating a new VM (App Connector first-boot can take several minutes) |

> **Per-zone sizing.** With `az_count = 2` and `max_size = 4`, the cluster scales up to **8 instances total** (4 per zone). This matches the cloud-connector convention.

> **Provisioning key reuse.** Every VM the autoscaler launches enrolls with the **same** static provisioning key baked into the instance template. Set `provisioning_key_max_usage` (default `100`) comfortably above `max_size × len(zones)` to leave headroom for instance churn.

> **Connector cleanup.** Disconnected/scaled-in connectors are reaped tenant-side via the [`zpa_app_connector_assistant_schedule`](https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_app_connector_assistant_schedule) resource. That resource is **not** wired into this example by design — configure it once at the tenant level outside of this module.

## How to deploy

### Option 1 (guided)
From the `examples/` directory, run the `zsac` bash script:

```bash
./zsac up
# select: 2) base_ac_asg
# follow auth + sizing prompts
```

The script will detect your OS, download a pinned `terraform` binary into a temporary `bin/` directory, populate `terraform.tfvars` from your answers, then run `terraform init` + `terraform apply`.

### Option 2 (manual)
1. Edit `examples/base_ac_asg/terraform.tfvars` to set at minimum `project` and `region`.
2. Authenticate to ZPA via env vars (OneAPI: `ZSCALER_CLIENT_ID`, `ZSCALER_CLIENT_SECRET`, `ZSCALER_VANITY_DOMAIN`, `ZPA_CUSTOMER_ID`; or Legacy: `ZPA_CLIENT_ID`, `ZPA_CLIENT_SECRET`, `ZPA_CUSTOMER_ID`, `ZPA_CLOUD`, `ZSCALER_USE_LEGACY_CLIENT=true`).
3. Authenticate to GCP via either `gcloud auth application-default login` (recommended) or by setting `var.credentials` to a SA JSON keyfile path.
4. From `examples/base_ac_asg/`:

```bash
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
cd examples/base_ac_asg
terraform destroy
```

> **Heads-up:** `terraform destroy` removes the MIG and autoscaler. Connectors that have already enrolled with the ZPA tenant remain visible (in a disconnected state) until the tenant-wide assistant schedule reaps them, or you delete them manually via the ZPA Admin Portal.

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
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../../modules/terraform-zsac-bastion-gcp | n/a |
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
| <a name="input_app_connector_group_dns_query_type"></a> [app\_connector\_group\_dns\_query\_type](#input\_app\_connector\_group\_dns\_query\_type) | Whether to enable IPv4 or IPv6, or both, for DNS resolution of all applications in the App Connector Group | `string` | `"IPV4_IPV6"` | no |
| <a name="input_app_connector_group_enabled"></a> [app\_connector\_group\_enabled](#input\_app\_connector\_group\_enabled) | Whether this App Connector Group is enabled or not | `bool` | `true` | no |
| <a name="input_app_connector_group_latitude"></a> [app\_connector\_group\_latitude](#input\_app\_connector\_group\_latitude) | Latitude of the App Connector Group. Integer or decimal. With values in the range of -90 to 90 | `string` | `"37.33874"` | no |
| <a name="input_app_connector_group_location"></a> [app\_connector\_group\_location](#input\_app\_connector\_group\_location) | location of the App Connector Group in City, State, Country format. example: 'San Jose, CA, USA' | `string` | `"San Jose, CA, USA"` | no |
| <a name="input_app_connector_group_longitude"></a> [app\_connector\_group\_longitude](#input\_app\_connector\_group\_longitude) | Longitude of the App Connector Group. Integer or decimal. With values in the range of -90 to 90 | `string` | `"-121.8852525"` | no |
| <a name="input_app_connector_group_override_version_profile"></a> [app\_connector\_group\_override\_version\_profile](#input\_app\_connector\_group\_override\_version\_profile) | Optional: Whether the default version profile of the App Connector Group is applied or overridden. Default: false | `bool` | `true` | no |
| <a name="input_app_connector_group_upgrade_day"></a> [app\_connector\_group\_upgrade\_day](#input\_app\_connector\_group\_upgrade\_day) | Optional: App Connectors in this group will attempt to update to a newer version of the software during this specified day. Default value: SUNDAY. List of valid days (i.e., SUNDAY, MONDAY, etc) | `string` | `"SUNDAY"` | no |
| <a name="input_app_connector_group_upgrade_time_in_secs"></a> [app\_connector\_group\_upgrade\_time\_in\_secs](#input\_app\_connector\_group\_upgrade\_time\_in\_secs) | Optional: App Connectors in this group will attempt to update to a newer version of the software during this specified time. Default value: 66600. Integer in seconds (i.e., 66600). The integer should be greater than or equal to 0 and less than 86400, in 15 minute intervals | `string` | `"66600"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Default number of zonal MIGs to create based on availability zone count. One MIG + one autoscaler is created per zone. | `number` | `1` | no |
| <a name="input_bastion_ssh_allow_ip"></a> [bastion\_ssh\_allow\_ip](#input\_bastion\_ssh\_allow\_ip) | CIDR blocks of trusted networks for bastion host ssh access from Internet | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_byo_provisioning_key"></a> [byo\_provisioning\_key](#input\_byo\_provisioning\_key) | Bring your own App Connector Provisioning Key. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo\_provisioning\_key\_name | `bool` | `false` | no |
| <a name="input_byo_provisioning_key_name"></a> [byo\_provisioning\_key\_name](#input\_byo\_provisioning\_key\_name) | Existing App Connector Provisioning Key name | `string` | `"provisioning-key-tf"` | no |
| <a name="input_cooldown_period"></a> [cooldown\_period](#input\_cooldown\_period) | Number of seconds the autoscaler waits before it starts collecting information from a new instance. | `number` | `60` | no |
| <a name="input_credentials"></a> [credentials](#input\_credentials) | Optional path to a Google Cloud service account JSON key file. Leave unset (null) to fall back to Application Default Credentials (ADC), e.g. `gcloud auth application-default login` or a workload identity. The variable is also satisfied by the `GOOGLE_CREDENTIALS` env var read directly by the google provider. | `string` | `null` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | Time in seconds the MIG autohealing health check waits before checking a newly created instance. | `number` | `300` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Custom image name to be used for deploying App Connector appliances. Ideally all VMs should be on the same Image as templates always pull the latest from Google Marketplace. This variable is provided if a customer desires to override/retain an old image for existing deployments rather than upgrading and forcing a replacement. | `string` | `""` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of App Connectors to maintain in the autoscaling group (per zone) | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of App Connectors to maintain in the autoscaling group (per zone) | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zsac"` | no |
| <a name="input_project"></a> [project](#input\_project) | Google Cloud project name | `string` | n/a | yes |
| <a name="input_provisioning_key_association_type"></a> [provisioning\_key\_association\_type](#input\_provisioning\_key\_association\_type) | Specifies the provisioning key type for App Connectors or ZPA Private Service Edges. The supported values are CONNECTOR\_GRP and SERVICE\_EDGE\_GRP | `string` | `"CONNECTOR_GRP"` | no |
| <a name="input_provisioning_key_enabled"></a> [provisioning\_key\_enabled](#input\_provisioning\_key\_enabled) | Whether the provisioning key is enabled or not. Default: true | `bool` | `true` | no |
| <a name="input_provisioning_key_max_usage"></a> [provisioning\_key\_max\_usage](#input\_provisioning\_key\_max\_usage) | The maximum number of instances where this provisioning key can be used for enrolling an App Connector or Service Edge. For autoscaling, set this comfortably above var.max\_size * length(var.zones) to allow for instance churn. | `number` | `100` | no |
| <a name="input_region"></a> [region](#input\_region) | Google Cloud region | `string` | n/a | yes |
| <a name="input_subnet_ac"></a> [subnet\_ac](#input\_subnet\_ac) | A subnet IP CIDR for the App Connector VPC | `string` | `"10.0.1.0/24"` | no |
| <a name="input_subnet_bastion"></a> [subnet\_bastion](#input\_subnet\_bastion) | A subnet IP CIDR for the greenfield/test bastion host in the Management VPC | `string` | `"10.0.0.0/24"` | no |
| <a name="input_target_cpu_util_value"></a> [target\_cpu\_util\_value](#input\_target\_cpu\_util\_value) | Target value for the autoscaling policy. For ASGAverageCPUUtilization this is interpreted as a CPU utilization percentage (1-100). For ASGAverageNetworkIn/Out this is interpreted as bytes-per-second per instance. | `number` | `50` | no |
| <a name="input_target_tracking_metric"></a> [target\_tracking\_metric](#input\_target\_tracking\_metric) | Target tracking metric for the autoscaling policy. Names mirror AWS predefined metric types so callers can switch clouds without renaming. Approved values: ASGAverageCPUUtilization, ASGAverageNetworkIn, ASGAverageNetworkOut. | `string` | `"ASGAverageCPUUtilization"` | no |
| <a name="input_tls_key_algorithm"></a> [tls\_key\_algorithm](#input\_tls\_key\_algorithm) | algorithm for tls\_private\_key resource | `string` | `"RSA"` | no |
| <a name="input_use_user_code_method"></a> [use\_user\_code\_method](#input\_use\_user\_code\_method) | OAuth2 user-code onboarding (default). Each App Connector VM publishes its /etc/issue enrollment code as a guest attribute on first boot; Terraform reads them back and passes them to the App Connector Group's user\_codes attribute, which the ZPA provider verifies. Set to false to fall back to the legacy provisioning-key flow (one shared key, baked into the VM startup script). Note for autoscaling: only resolves codes for instances present at apply time. | `bool` | `true` | no |
| <a name="input_use_zscaler_image"></a> [use\_zscaler\_image](#input\_use\_zscaler\_image) | By default, App Connector will deploy via the Zscaler Latest Image. Setting this to false will deploy the latest Red Hat Enterprise Linux 9 Image instead | `bool` | `true` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | (Optional) Availability zone names. Only required if automatic zones selection based on az\_count is undesirable | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | Google Cloud Testbed results |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
