# Zscaler App Connector / GCP Autoscaling (ASG) Module

This module deploys Zscaler App Connector instances on GCP using a per-zone **Managed Instance Group + Compute Autoscaler**, mirroring the surface and defaults of the AWS [`terraform-zsac-asg-aws`](https://github.com/zscaler/terraform-aws-zpa-app-connector-modules/tree/main/modules/terraform-zsac-asg-aws) module.

For each zone in `var.zones`, this module creates:

1. **One** `google_compute_instance_template` (shared across zones)
2. **One** `google_compute_instance_group_manager` (zonal MIG) with auto-healing wired to a TCP health check on port 22
3. **One** `google_compute_autoscaler` policy attached to that MIG

Group size is owned by the autoscaler, not Terraform — the MIG resource declares `ignore_changes = [target_size]` so the autoscaler is the single source of truth at run time.

## Scaling metric

Variable `target_tracking_metric` is named after AWS's `predefined_metric_type` so callers can switch clouds without renaming. The mapping to GCP-native autoscaler blocks is:

| `target_tracking_metric` | GCP encoding | Interpretation of `target_cpu_util_value` |
|---|---|---|
| `ASGAverageCPUUtilization` (default) | `cpu_utilization { target = X / 100 }` | CPU % (1–100), divided by 100 because GCP wants a 0.0–1.0 fraction |
| `ASGAverageNetworkIn` | `metric { name = "compute.googleapis.com/instance/network/received_bytes_count"; type = "DELTA_PER_SECOND" }` | Bytes per second per instance |
| `ASGAverageNetworkOut` | `metric { name = "compute.googleapis.com/instance/network/sent_bytes_count"; type = "DELTA_PER_SECOND" }` | Bytes per second per instance |

Zscaler recommends `ASGAverageCPUUtilization`. The other two are provided for parity with the AWS module's surface.

## Bootstrap

Bootstrap is identical to the fixed-size [`terraform-zsac-acvm-gcp`](../terraform-zsac-acvm-gcp/) module: a static App Connector **provisioning key** is baked into `var.user_data` and consumed by every instance the MIG launches. The provisioning key itself is created (or referenced) by the [`terraform-zpa-provisioning-key`](../terraform-zpa-provisioning-key/) module in the parent example.

## What this module does NOT do

To keep the surface tight and aligned with the AWS module, this module deliberately omits:

- **Internal Load Balancer.** App Connectors dial out to the Zscaler cloud; no inbound LB is needed.
- **Cloud Function / Cloud Scheduler for scale-in cleanup.** Disconnected App Connectors are reaped tenant-side by the [`zpa_app_connector_assistant_schedule`](https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_app_connector_assistant_schedule) resource (configured separately).
- **Custom Stackdriver metrics.** Cloud Connector ships its own `smedge_cpu_utilization` metric; App Connector does not, so we use native GCE signals instead.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 7.31.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.12.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 7.31.0 |
| <a name="provider_time"></a> [time](#provider\_time) | ~> 0.12.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_autoscaler.ac_asg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_autoscaler) | resource |
| [google_compute_health_check.ac_asg_health_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_instance_group_manager.ac_instance_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager) | resource |
| [google_compute_instance_template.ac_instance_template](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | resource |
| [time_sleep.wait_60_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [google_compute_instance_group.ac_instance_groups](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_instance_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acvm_instance_type"></a> [acvm\_instance\_type](#input\_acvm\_instance\_type) | App Connector Instance Type | `string` | `"n2-standard-4"` | no |
| <a name="input_acvm_vpc_subnetwork"></a> [acvm\_vpc\_subnetwork](#input\_acvm\_vpc\_subnetwork) | VPC subnetwork the App Connector instances are launched in | `string` | n/a | yes |
| <a name="input_cooldown_period"></a> [cooldown\_period](#input\_cooldown\_period) | The number of seconds the autoscaler waits before it starts collecting information from a new instance. Prevents the autoscaler from acting on usage data while the instance is still initializing. | `number` | `60` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | The size of the boot disk in gigabytes. If not specified, it will inherit the size of its base image | `string` | `"64"` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | Time in seconds the autohealing health check waits before checking a newly created instance. Mirrors AWS health\_check\_grace\_period semantics. | `number` | `300` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Custom image name to be used for deploying App Connector appliances. Ideally all VMs should be on the same image as templates always pull the latest from Google Marketplace. | `string` | `""` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of App Connectors to maintain in the autoscaling group (per zone) | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of App Connectors to maintain in the autoscaling group (per zone) | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the App Connector ASG module resources | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Google Cloud project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Google Cloud region | `string` | n/a | yes |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the App Connector ASG module resources | `string` | `null` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | Email of the service account to attach to the App Connector VMs. Required for OAuth user-code onboarding (the VM PUTs its enrollment code to the GCE metadata server's guest-attributes endpoint, which is authenticated as this SA against the Compute API). Leave null to use the project's default Compute Engine service account; otherwise pass an SA email that has roles/compute.instanceAdmin.v1 (or the more granular compute.instances.setGuestAttributes permission) on the project. | `string` | `null` | no |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | A public key uploaded to the App Connector instances | `string` | n/a | yes |
| <a name="input_target_cpu_util_value"></a> [target\_cpu\_util\_value](#input\_target\_cpu\_util\_value) | Target value for the autoscaling policy. For ASGAverageCPUUtilization this is interpreted as a CPU utilization percentage (1-100, divided by 100 internally because GCP wants a 0.0-1.0 fraction). For ASGAverageNetworkIn/Out this is interpreted as bytes-per-second per instance. | `number` | `50` | no |
| <a name="input_target_tracking_metric"></a> [target\_tracking\_metric](#input\_target\_tracking\_metric) | Target tracking metric for the autoscaling policy. Names mirror AWS predefined metric types so callers can switch clouds without renaming. App Connector recommends ASGAverageCPUUtilization. | `string` | `"ASGAverageCPUUtilization"` | no |
| <a name="input_update_max_unavailable_fixed"></a> [update\_max\_unavailable\_fixed](#input\_update\_max\_unavailable\_fixed) | Maximum number of instances that can be unavailable during the update process. | `number` | `1` | no |
| <a name="input_update_policy_max_surge_fixed"></a> [update\_policy\_max\_surge\_fixed](#input\_update\_policy\_max\_surge\_fixed) | Maximum number of instances created above the specified target\_size during the update process. | `number` | `1` | no |
| <a name="input_update_policy_replacement_method"></a> [update\_policy\_replacement\_method](#input\_update\_policy\_replacement\_method) | The instance replacement method for the MIG. SUBSTITUTE replaces VMs with new ones with random names; RECREATE preserves names but requires max\_unavailable\_fixed > 0. | `string` | `"SUBSTITUTE"` | no |
| <a name="input_update_policy_type"></a> [update\_policy\_type](#input\_update\_policy\_type) | The type of update process. PROACTIVE drives instances to their target version actively; OPPORTUNISTIC only updates as part of other actions. | `string` | `"OPPORTUNISTIC"` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Cloud Init / startup-script data executed by every instance launched from the template | `string` | n/a | yes |
| <a name="input_zones"></a> [zones](#input\_zones) | Availability zone names. One Managed Instance Group + one Autoscaler is created per zone. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaler_ids"></a> [autoscaler\_ids](#output\_autoscaler\_ids) | self\_link IDs of the per-zone Compute Autoscalers |
| <a name="output_autoscaler_names"></a> [autoscaler\_names](#output\_autoscaler\_names) | Names of the per-zone Compute Autoscalers |
| <a name="output_instance_group_ids"></a> [instance\_group\_ids](#output\_instance\_group\_ids) | self\_link IDs of the per-zone Managed Instance Groups |
| <a name="output_instance_group_names"></a> [instance\_group\_names](#output\_instance\_group\_names) | Names of the per-zone Managed Instance Groups created by the autoscaler |
| <a name="output_instance_group_zones"></a> [instance\_group\_zones](#output\_instance\_group\_zones) | GCP zone assignments for the per-zone Managed Instance Groups |
| <a name="output_instance_template_project"></a> [instance\_template\_project](#output\_instance\_template\_project) | GCP project for the App Connector instance template |
| <a name="output_instance_template_region"></a> [instance\_template\_region](#output\_instance\_template\_region) | GCP region for the App Connector instance template |
| <a name="output_running_instance_names"></a> [running\_instance\_names](#output\_running\_instance\_names) | Names of every VM currently registered across all MIGs (parallel list to running\_instance\_zones). Pass to the user-code resolver as instance\_names. |
| <a name="output_running_instance_zones"></a> [running\_instance\_zones](#output\_running\_instance\_zones) | Zones for every VM currently registered across all MIGs (parallel list to running\_instance\_names). Pass to the user-code resolver as instance\_zones. |
| <a name="output_running_instances"></a> [running\_instances](#output\_running\_instances) | Per-zone list of VM instance self\_links currently registered to each MIG (queried 60s after MIG creation to give instances time to come up). Useful for debugging and for terratest assertions that count live instances. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
