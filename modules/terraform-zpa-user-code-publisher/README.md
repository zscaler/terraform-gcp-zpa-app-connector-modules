# terraform-zpa-user-code-publisher

PUBLISHER half of the OAuth onboarding flow for Zscaler Private Access App
Connectors on GCP. Used together with `terraform-zpa-user-code-reader`.

This module owns:

* `vm_count` Secret Manager secrets, named `<prefix>-<tag>-zpa-user-code-<i>`.
* IAM bindings (`roles/secretmanager.secretVersionAdder`,
  `roles/secretmanager.secretAccessor`) granting the VM service account
  publish + read on each secret.
* The bash startup script (`output.user_data`) the VMs run on first boot.
  The script reads `/etc/issue`, finds the OAuth enrollment code, and
  publishes it to its assigned slot via `gcloud secrets versions add`.

It does NOT read secret versions back into Terraform — that's the reader
module's job. The split is deliberate: if both halves lived in one module,
anything that consumed `user_data` would transitively depend on the data
sources (and the `time_sleep` they're gated by), which would block VM
creation until after the sleep — at which point the sleep would have
expired with no VMs to publish anything.

## Wiring

```hcl
module "user_code_publisher" {
  source                = "../../modules/terraform-zpa-user-code-publisher"
  name_prefix           = var.name_prefix
  resource_tag          = random_string.suffix.result
  project               = var.project
  vm_count              = var.ac_count * length(local.zones_list)
  service_account_email = google_service_account.ac_vm.email
}

module "ac_vm" {
  source    = "../../modules/terraform-zsac-acvm-gcp"
  user_data = module.user_code_publisher.user_data
  # ...
}

module "user_code_reader" {
  source        = "../../modules/terraform-zpa-user-code-reader"
  project       = var.project
  secret_ids    = module.user_code_publisher.secret_ids
  secrets_ready = module.user_code_publisher.secrets_ready
  vms_ready     = module.ac_vm.ac_instance_names
}

module "zpa_app_connector_group_oauth" {
  source     = "../../modules/terraform-zpa-app-connector-group"
  user_codes = module.user_code_reader.user_codes
  # ...
}
```

## Required APIs

* `secretmanager.googleapis.com`
