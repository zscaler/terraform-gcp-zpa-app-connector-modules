![GitHub release (latest by date)](https://img.shields.io/github/v/release/zscaler/terraform-gcp-zpa-app-connector-modules?style=flat-square)
![GitHub](https://img.shields.io/github/license/zscaler/terraform-gcp-zpa-app-connector-modules?style=flat-square)
![GitHub pull requests](https://img.shields.io/github/issues-pr/zscaler/terraform-gcp-zpa-app-connector-modules?style=flat-square)
![Terraform registry downloads total](https://img.shields.io/badge/dynamic/json?color=green&label=downloads%20total&query=data.attributes.total&url=https%3A%2F%2Fregistry.terraform.io%2Fv2%2Fmodules%2Fzscaler%2Fzpa-app-connector-modules%2Fgcp%2Fdownloads%2Fsummary&style=flat-square)
![Terraform registry download month](https://img.shields.io/badge/dynamic/json?color=green&label=downloads%20this%20month&query=data.attributes.month&url=https%3A%2F%2Fregistry.terraform.io%2Fv2%2Fmodules%2Fzscaler%2Fzpa-app-connector-modules%2Fgcp%2Fdownloads%2Fsummary&style=flat-square)
[![Automation Hub](https://img.shields.io/badge/automation-hub-blue)](https://automate.zscaler.com/docs/tools/sdk-documentation/sdk-getting-started)
[![Zscaler Community](https://img.shields.io/badge/zscaler-community-blue)](https://community.zscaler.com/)

# Zscaler App Connector GCP Terraform Modules

> Production-grade Terraform modules for deploying Zscaler Private Access (ZPA) App Connectors on Google Cloud — including fixed-size and autoscaling group deployments.

## Support Disclaimer

-> **Disclaimer:** Please refer to our [General Support Statement](docs/guides/support.md) before proceeding with the use of this provider.

## Description

This repository contains reusable Terraform modules and four ready-to-run example deployments that stand up ZPA App Connector appliances on GCP and enroll them with the Zscaler Zero Trust Exchange. The deployments are intended to be fully functional and self-service for both greenfield/PoV and production use, and can also be referenced as design templates per Zscaler's [Zero Trust Access to Private Apps in GCP with ZPA](https://www.zscaler.com/resources/reference-architecture/zero-trust-with-zpa.pdf) reference architecture.

~> **IMPORTANT** As of version 1.1.0, all App Connectors are deployed using the new [Red Hat Enterprise Linux 9](https://help.zscaler.com/zpa/app-connector-red-hat-enterprise-linux-9-migration) image.

## What's in this repository

```
.
├── modules/                                # Reusable building blocks (Hashicorp standard module layout)
│   ├── terraform-zsac-network-gcp           # VPC, subnets, Cloud Router, Cloud NAT, firewall rules
│   ├── terraform-zsac-bastion-gcp           # Optional bastion host for SSH jump access
│   ├── terraform-zsac-acvm-gcp              # FIXED-size App Connector deployment (instance template + per-zone MIGs)
│   ├── terraform-zsac-asg-gcp               # AUTOSCALING App Connector deployment (instance template + per-zone MIGs + autoscalers)
│   ├── terraform-zpa-app-connector-group    # Creates / manages a ZPA App Connector Group
│   └── terraform-zpa-provisioning-key       # Creates / references a ZPA Provisioning Key
│
└── examples/                                # Four end-to-end example deployments
    ├── base_ac        # GREENFIELD, FIXED size      (new VPC + bastion + N App Connectors)
    ├── base_ac_asg    # GREENFIELD, AUTOSCALING     (new VPC + bastion + autoscaling group)
    ├── ac             # BROWNFIELD, FIXED size      (BYO VPC/subnets/router/NAT, no bastion)
    ├── ac_asg         # BROWNFIELD, AUTOSCALING     (BYO network, no bastion, production autoscaling)
    └── zsec           # Wrapper bash script that walks first-time users through prompts
```

## Choosing a deployment type

| Scenario | Use |
| --- | --- |
| First-time PoC / lab on a clean project | `examples/base_ac` |
| Lab with autoscaling validation | `examples/base_ac_asg` |
| Production, fixed App Connector count, integrate with an existing VPC | `examples/ac` |
| Production, autoscaling, integrate with an existing VPC | `examples/ac_asg` |

**Greenfield (`base_*`)** examples create *new* network plumbing (Management VPC, subnets, Cloud Router, Cloud NAT, optional bastion host with an SSH key pair generated locally). They are convenient for PoVs but place hosts/services and applications in the same project, which is not a GCP best practice for production.

**Brownfield (`ac` / `ac_asg`)** examples expect a real production environment: BYO VPC, BYO subnet, BYO Cloud Router, BYO NAT, no bastion. Every BYO option is independently togglable, so you can mix and match (e.g. existing VPC + new subnet).

**Fixed (`base_ac` / `ac`)** examples create a known number of App Connectors per zone (`ac_count`). The VMs are still managed by zonal MIGs (for self-healing), but the size is pinned — there is no autoscaler.

**Autoscaling (`base_ac_asg` / `ac_asg`)** examples add a `google_compute_autoscaler` per zonal MIG, scaling between `min_size` and `max_size` based on a target-tracking metric (CPU, NetworkIn, or NetworkOut).

## Prerequisites

### Terraform & providers

* Terraform `>= 1.5` (tested up to the latest 1.x). Versions back to `0.13.7` are generally supported.
* `hashicorp/google >= 5.0`
* `hashicorp/random >= 3.6`
* `hashicorp/local >= 2.5`
* `hashicorp/null >= 3.2`
* `hashicorp/tls >= 4.0`
* `zscaler/zpa >= 3.31`

The providers are version-pinned inside each module's `versions.tf`. Run `terraform init` from your chosen example directory to pull them down.

### GCP

1. A GCP project with billing enabled and the following APIs:
   * `compute.googleapis.com`
   * `iam.googleapis.com`
   * `cloudresourcemanager.googleapis.com`
2. Network / Compute admin permissions in the target project. The simplest path is `roles/owner` or, for least privilege:
   * `roles/compute.admin`
   * `roles/iam.serviceAccountUser` (if the App Connector VMs reference a non-default SA)
3. **Authentication** — Terraform uses the `hashicorp/google` provider. Either:
   * **Recommended:** Application Default Credentials (`gcloud auth application-default login`). Leave the `credentials` tfvar commented out.
   * Service Account JSON keyfile. Set the `credentials` tfvar to the file path. Make sure the SA has the roles listed above.
4. A region (e.g. `us-central1`) and one or more zones (e.g. `us-central1-a`, `us-central1-b`). Multi-zone deployment is controlled with `var.az_count` (1–3) or `var.zones` (explicit list).

### Zscaler (ZPA)

This module uses the [ZPA Terraform Provider](https://registry.terraform.io/providers/zscaler/zpa/latest/docs) for the automated onboarding step (creating the App Connector Group and Provisioning Key, then injecting the key into the VM first-boot script).

1. A valid Zscaler Private Access subscription and portal access.
2. Zscaler ZPA API keys. See [About API Keys](https://help.zscaler.com/zpa/about-api-keys) for how to generate them. You will need:
   * Client ID
   * Client Secret
   * Customer ID
3. **(Optional)** An existing App Connector Group and Provisioning Key, if you'd rather reuse them than have Terraform create new ones — see [`byo_provisioning_key`](#bring-your-own-provisioning-key) below.

The recommended way to supply ZPA credentials is via environment variables so they never end up in `terraform.tfvars` or state:

```bash
export ZPA_CLIENT_ID="<client-id>"
export ZPA_CLIENT_SECRET="<client-secret>"
export ZPA_CUSTOMER_ID="<customer-id>"
# Optional - defaults to "PRODUCTION"
export ZPA_CLOUD="PRODUCTION"   # or BETA, ZPATWO, GOV, GOVUS
```

See: [Zscaler App Connector Deployment for Linux](https://help.zscaler.com/zpa/app-connector-deployment-guide-linux) for end-to-end prerequisite walk-throughs.

### Operator workstation

If you run Terraform directly (the recommended path for production), you only need Terraform itself plus `gcloud`. If you use the `zsec` wrapper bash script for a guided first-time deployment, the workstation needs:

* `bash`
* `curl`
* `unzip`

The script auto-downloads a pinned Terraform version into a temporary directory, so Terraform doesn't have to be pre-installed.

## Quick start

### Option A — direct Terraform (recommended for production)

```bash
git clone https://github.com/zscaler/terraform-gcp-zpa-app-connector-modules.git
cd terraform-gcp-zpa-app-connector-modules/examples/base_ac    # or ac, base_ac_asg, ac_asg

# Authenticate
gcloud auth application-default login
export ZPA_CLIENT_ID="..."
export ZPA_CLIENT_SECRET="..."
export ZPA_CUSTOMER_ID="..."

# Configure
cp terraform.tfvars terraform.tfvars.local   # template lives in each example
$EDITOR terraform.tfvars                     # uncomment and set values

terraform init
terraform plan
terraform apply
```

### Option B — `zsec` wrapper (recommended for first-time / PoV)

```bash
cd terraform-gcp-zpa-app-connector-modules/examples
./zsec up        # interactive prompts for deployment type + credentials
# ...
./zsec destroy   # tears everything down
```

The script writes a `.zsecrc` in the working directory with your answers so subsequent runs skip the prompts. Delete it if you need to change credentials or region.

## App Connector onboarding (how it works)

This module uses the **provisioning-key** enrollment method:

1. Terraform creates (or references) an App Connector Group and a Provisioning Key in your ZPA tenant via the ZPA provider.
2. The provisioning key string is rendered into the VM's first-boot user-data script.
3. On boot, the script writes the key to `/opt/zscaler/var/provision_key`, starts the `zpa-connector` systemd service, and the connector enrolls itself with your ZPA tenant.

Each App Connector consumes one slot against the provisioning key's `max_usage`. For autoscaling deployments be sure to size `max_usage` well above `max_size * length(zones)` to leave headroom for instance churn over the life of the cluster — instance replacements consume new slots even though the old VMs are gone.

### Bring-your-own provisioning key

By default, every example creates a fresh App Connector Group and Provisioning Key. To reuse an existing key (typical for production tenants with established provisioning policy):

```hcl
byo_provisioning_key      = true
byo_provisioning_key_name = "my-existing-key-name"
```

When `byo_provisioning_key = true` the App Connector Group inputs (`app_connector_group_*`) are ignored — the existing key already binds to its own group.

## Configuration reference — most-used variables

The full input surface lives in each example's `variables.tf` and is reproduced in the sample `terraform.tfvars`. The variables most operators touch:

| Variable | Default | Description |
| --- | --- | --- |
| `project` | — | GCP project ID for all created resources |
| `region` | — | GCP region (e.g. `us-central1`) |
| `name_prefix` | `zsac` | Prefix for resource names. Must be ≤ 12 chars, lowercase |
| `az_count` | `1` | How many zones to spread MIGs across (1–3). Ignored if `zones` is set explicitly |
| `zones` | `[]` | Explicit zone list (overrides `az_count`) |
| `ac_count` | `1` | (fixed examples) Number of App Connectors per zonal MIG |
| `min_size` / `max_size` | `2` / `4` | (ASG examples) Per-zone instance count bounds |
| `target_tracking_metric` | `ASGAverageCPUUtilization` | (ASG) `ASGAverageCPUUtilization` \| `ASGAverageNetworkIn` \| `ASGAverageNetworkOut` |
| `target_cpu_util_value` | `50` | (ASG) Target value for the metric (CPU=%, Network=bytes/sec) |
| `acvm_instance_type` | `n2-standard-4` | One of the [Zscaler-approved sizes](https://help.zscaler.com/zpa/app-connector-deployment-guide-linux#instance-sizing) |
| `use_zscaler_image` | `true` | Use the Zscaler-published Marketplace image (recommended) vs base RHEL 9 |
| `image_name` | `""` | Pin a specific image name (escape hatch — not recommended; Zscaler ships frequent updates) |
| `byo_vpc` / `byo_subnets` / `byo_router` / `byo_natgw` | `false` | (brownfield) Reuse existing network primitives instead of creating new ones |
| `subnet_bastion` / `subnet_ac` | `10.0.0.0/24` / `10.0.1.0/24` | (greenfield) CIDR ranges; minimum `/28` |

Notes:
* The "Connector" enrollment certificate and the "Default" version profile are auto-resolved inside the modules via `data "zpa_enrollment_cert"` / `data "zpa_customer_version_profile"`. They are no longer surfaced as inputs.
* The autoscaling metric names mirror the AWS ASG predefined metric types so callers can move between clouds without renaming.

## Sizing the App Connector cluster

| Workload | Recommended baseline |
| --- | --- |
| Lab / PoV | 1 App Connector in 1 zone (`ac_count = 1`, `az_count = 1`) |
| Small production | 2 App Connectors across 2 zones (`ac_count = 2`, `az_count = 2`) |
| Autoscaling production | `min_size = 2`, `max_size = 4` per zone across 2-3 zones |

App Connector load characteristics:
* CPU-bound for TLS termination and tunnel processing.
* Network-bound for high-throughput file/data workloads.

For autoscaling, `ASGAverageCPUUtilization` is the right default for typical Zero Trust app access (mix of small interactive sessions). Switch to `ASGAverageNetworkIn` / `Out` only if you've validated that your workload is genuinely network-bound.

## Operational notes

* **Image freshness.** The default lookup pulls the latest Zscaler-published `zpa-connector-el9-*` image from the GCP Marketplace project at every apply. To get a new image rolled into existing instances, run `terraform apply` — the instance template will be replaced, and the MIG's `update_policy` will roll the change through the running VMs. Pin `image_name` only if you need to freeze a specific version.
* **VM admin user.** The compute modules create the OS user `admin` and inject the public key from `tls_private_key.key` into its `authorized_keys`. The private key is written to a local `.pem` file in the example directory (and `chmod 600`). Treat this file as a secret.
* **State file contains secrets.** The provisioning key string lives in state. Use a remote backend with encryption at rest (`gcs` is the natural choice for GCP) and restrict access. **Never commit state to source control.**
* **Destroying.** `terraform destroy` will tear down the VMs, MIGs, autoscalers, network plumbing, ZPA App Connector Group and Provisioning Key. The App Connectors will go offline immediately. If you have ZPA policies referencing the group, detach them first.
* **`update_policy_replacement_method`.** Defaults to `SUBSTITUTE` (new VMs are launched with new names before old ones are removed) which preserves App Connector enrollment continuity during image updates. Change to `RECREATE` only if you need to preserve VM names.

## Module quick-reference

Each module under `modules/` is independently consumable if you prefer to compose your own deployment instead of using the provided examples. Refer to each module's own `README.md` for inputs, outputs, and a minimal usage snippet:

* [`modules/terraform-zsac-network-gcp`](modules/terraform-zsac-network-gcp/README.md)
* [`modules/terraform-zsac-bastion-gcp`](modules/terraform-zsac-bastion-gcp/README.md)
* [`modules/terraform-zsac-acvm-gcp`](modules/terraform-zsac-acvm-gcp/README.md) — fixed-size
* [`modules/terraform-zsac-asg-gcp`](modules/terraform-zsac-asg-gcp/README.md) — autoscaling
* [`modules/terraform-zpa-app-connector-group`](modules/terraform-zpa-app-connector-group/README.md)
* [`modules/terraform-zpa-provisioning-key`](modules/terraform-zpa-provisioning-key/README.md)

## Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| `terraform plan` errors with "Could not find a tag" against the Zscaler marketplace | The `mpi-zpa-gcp-marketplace` image hasn't been accepted in your project yet. Accept the Marketplace EULA once via console and re-run. |
| App Connectors come up healthy but the ZPA portal shows them disconnected | `max_usage` on the provisioning key was exceeded. Either bump the key's `provisioning_key_max_usage` or rotate the key. |
| `terraform apply` succeeds but the VM never enrolls | SSH into the VM (via bastion in greenfield, via your normal jump path in brownfield) and inspect `journalctl -u zpa-connector` and `/opt/zscaler/var/provision_key`. The most common causes are (a) outbound to ZPA cloud blocked by a firewall rule, (b) NAT egress missing, (c) DNS misconfigured. |
| Autoscaler immediately scales to `max_size` and stays there | `target_cpu_util_value` is too low for your workload's baseline, or the App Connector first-boot CPU spike is being measured. Bump `health_check_grace_period` (default 300s) and/or raise the target value. |
| "Address space exhausted" on subnet creation | `subnet_ac` / `subnet_bastion` overlap an existing CIDR in your project. Pick non-overlapping ranges. |

## Format

This repository follows the [Hashicorp Standard Modules Structure](https://www.terraform.io/registry/modules/publish):

* `modules` — building blocks. Each module is independently consumable and is intentionally minimal and reusable.
* `examples` — end-to-end reference deployments. Useful as both runnable starting points and design references. The `zsec` wrapper script lets novice operators stand up a deployment without installing Terraform locally.

## Versioning

These modules follow [Semantic Versioning](http://semver.org/). Releases (with changelog) live on the GitHub [Releases](https://github.com/zscaler/terraform-gcp-zpa-app-connector-modules/releases) page.

## Contributing

Issues and pull requests are welcome on the [GitHub repository](https://github.com/zscaler/terraform-gcp-zpa-app-connector-modules). For Zscaler-specific support questions, the [Zscaler Community](https://community.zscaler.com/) is the right venue.

# License and Copyright

Copyright (c) 2022 Zscaler, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
