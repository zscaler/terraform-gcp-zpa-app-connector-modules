# terraform-zpa-user-code-reader

READER half of the OAuth onboarding flow for Zscaler Private Access App
Connectors on GCP. Used together with `terraform-zpa-user-code-publisher`.

This module owns:

* A `time_sleep` that bridges "VMs created" -> "VMs published their codes
  to Secret Manager".
* One `data "google_secret_manager_secret_version"` per slot. Failure
  surfaces as `Error 404: Secret has no versions` — which is the loud
  signal that the VM didn't publish in time.

It does NOT create the secrets — that's the publisher module's job. It
also does NOT depend on the publisher's `user_data` output; this means a
consumer can wire `ac_vm.user_data = publisher.user_data` (so VMs come up
fast) and then have the reader wait for VM publication separately.

## Wiring

See `terraform-zpa-user-code-publisher` README for the full example.
