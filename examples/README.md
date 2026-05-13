# Zscaler App Connector Example Deployments

End-to-end reference deployments for Zscaler Private Access (ZPA) App Connectors on Google Cloud.

This directory holds **four** working example configurations plus the `zsec` wrapper script that walks first-time operators through prompts. Pick the example that matches your scenario and either run Terraform directly against it or invoke `zsec`.

## Choosing an example

| Example          | Network        | Cluster topology  | Bastion | Best for                                                |
| ---------------- | -------------- | ----------------- | ------- | ------------------------------------------------------- |
| `base_ac`        | NEW VPC + NAT  | FIXED `ac_count`  | yes     | Lab / PoV / first-time customer demo                    |
| `base_ac_asg`    | NEW VPC + NAT  | AUTOSCALING       | yes     | Autoscaling lab / load validation                       |
| `ac`             | BYO            | FIXED `ac_count`  | no      | Production with a known steady-state connector count   |
| `ac_asg`         | BYO            | AUTOSCALING       | no      | Production with variable load — the recommended target |

**Greenfield (`base_*`)** examples create a fresh "Management" VPC with a public bastion subnet, an App Connector subnet, a Cloud Router + NAT gateway, and an SSH key pair generated locally (`<name_prefix>-key-<suffix>.pem`). Convenient for PoVs, not a GCP best practice for production (host plane and app plane share a project).

**Brownfield (`ac` / `ac_asg`)** examples expect a real production environment. Every network primitive (VPC, subnet, Cloud Router, NAT) has a `byo_*` toggle so you can reuse existing infrastructure where it exists and let Terraform create what doesn't.

**Fixed (`base_ac` / `ac`)** examples deploy a pinned number of App Connectors per zone (`ac_count`). VMs are still managed by zonal MIGs for self-healing, but there is no autoscaler.

**Autoscaling (`base_ac_asg` / `ac_asg`)** examples add a `google_compute_autoscaler` per zonal MIG, scaling between `min_size` and `max_size` based on a target-tracking metric (CPU, NetworkIn, or NetworkOut). Metric names mirror AWS ASG predefined types so callers can move between clouds without renaming.

## Prerequisites

(You will be prompted for these during `zsec up` if you use the wrapper.)

### GCP

1. GCP project with billing enabled.
2. Enabled APIs: `compute.googleapis.com`, `iam.googleapis.com`, `cloudresourcemanager.googleapis.com`.
3. **Authentication:**
   - Recommended: Application Default Credentials (`gcloud auth application-default login`). Leave the `credentials` tfvar commented out.
   - Or: a service account JSON keyfile with at least `roles/compute.admin` and `roles/iam.serviceAccountUser`. Set the `credentials` tfvar to the file path.
4. A region (`us-central1`) and one or more zones.

### Zscaler ZPA

1. A valid ZPA subscription and portal access.
2. ZPA API keys. See [About API Keys](https://help.zscaler.com/zpa/about-api-keys). You need Client ID, Client Secret, Customer ID.
3. (Optional) An existing App Connector Group + Provisioning Key, if you'd rather reuse them than have Terraform create new ones — see `byo_provisioning_key` in the example's `terraform.tfvars`.

Recommended: pass ZPA credentials via environment variables so they never land in `terraform.tfvars` or state:

```bash
export ZPA_CLIENT_ID="<client-id>"
export ZPA_CLIENT_SECRET="<client-secret>"
export ZPA_CUSTOMER_ID="<customer-id>"
export ZPA_CLOUD="PRODUCTION"   # optional; defaults to PRODUCTION
```

See: [Zscaler App Connector Deployment for Linux](https://help.zscaler.com/zpa/app-connector-deployment-guide-linux) for end-to-end prerequisite walk-throughs.

### Operator workstation

If you invoke Terraform directly: you need Terraform itself plus `gcloud`.

If you use the `zsec` wrapper script (auto-downloads a pinned Terraform into a temp dir):
- `bash`
- `curl`
- `unzip`

## Deploying — direct Terraform (recommended for production)

```bash
cd examples/<deployment-type>     # base_ac | base_ac_asg | ac | ac_asg

# Edit the sample tfvars to your environment. Every value is commented out
# by default so the example runs with sensible defaults out of the box.
$EDITOR terraform.tfvars

terraform init
terraform plan
terraform apply
```

## Deploying — `zsec` wrapper (interactive)

The `zsec` script is intended for first-time operators or customer-demo scenarios where you'd rather answer prompts than edit tfvars. It can be run from macOS, Linux, or any GCP Cloud Shell.

```bash
cd examples
./zsec up
# - choose "greenfield" or "brownfield"
# - choose a deployment type
# - answer the prompts (or accept defaults)
#
# zsec then:
#   1. Validates inputs and writes a .zsecrc cache for subsequent runs
#   2. Downloads a pinned Terraform into a temporary bin directory
#   3. Runs terraform init / plan / apply for the chosen example
#   4. Prompts you to type "yes" to confirm the plan
```

> **Note:** any value you set in `terraform.tfvars` overrides the equivalent `zsec` prompt.

### Greenfield deployment types

```
base_ac
  1 new Management VPC + AC subnet + bastion subnet, 1 Cloud Router + NAT,
  1 bastion host with auto-generated SSH key pair, 1 App Connector compute
  instance template, X per-zone MIGs of FIXED size (controlled by ac_count).
  Use this for first-time PoV/lab.

base_ac_asg
  Same network/bastion topology as base_ac, but the App Connector cluster is
  AUTOSCALING. One Compute Instance Template + N per-zone MIGs + N per-zone
  Compute Autoscalers scaling between min_size and max_size on a target-
  tracking metric (CPU, NetworkIn, or NetworkOut). Use for autoscaling
  validation labs.
```

### Brownfield deployment types

```
ac
  1 new Management VPC + AC subnet, 1 Cloud Router + NAT, generated SSH key
  pair, 1 App Connector compute instance template, X per-zone MIGs of FIXED
  size (controlled by ac_count). Every network primitive is byo_* togglable
  (VPC, subnet, Cloud Router, NAT). No bastion. Use for production with a
  steady-state connector count.

ac_asg
  Same brownfield BYO surface as ac (no bastion, optional VPC/subnet/router/
  NAT reuse), but AUTOSCALING. One Compute Instance Template + N per-zone
  MIGs + N per-zone Compute Autoscalers. This is the production-grade
  autoscaling deployment.
```

## Destroying

```bash
cd examples
./zsec destroy           # interactive wrapper
# - confirm with "yes"
```

or, when running Terraform directly:

```bash
cd examples/<deployment-type>
terraform destroy
```

> **Warning:** destroy removes the App Connectors *and* the ZPA App Connector Group and Provisioning Key. If you have ZPA access policies referencing the group, detach them first or the destroy will fail on the ZPA side.

## Sizing the provisioning key

The module creates a ZPA Provisioning Key with `max_usage` (default `10` for fixed, `100` for ASG). Each App Connector consumes one slot at enrollment time and instance churn (image upgrades, scale-in/out, MIG replacements) consumes additional slots even though the old VMs are gone. For autoscaling deployments size `provisioning_key_max_usage` well above `max_size * length(zones)` to leave headroom — running out causes new VMs to come up healthy at the OS level but show as disconnected in the ZPA portal.

## Notes

```
1. For auto-approval set environment variable AUTO_APPROVE (or `export AUTO_APPROVE=1`).
2. To pre-select a deployment type set `dtype` (or `export dtype=base_ac`).
3. To rotate credentials or change region, delete the autogenerated .zsecrc
   in the working directory and re-run `./zsec up`.
4. The example tfvars are TEMPLATES — every value is commented out. The
   example runs end-to-end with the defaults if you only supply `project`
   (and a few BYO names for the brownfield examples).
```
