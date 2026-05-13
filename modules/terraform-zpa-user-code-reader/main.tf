################################################################################
# OAuth user-code READER half of the OAuth onboarding flow.
#
# Owns:
#   * A `time_sleep` that bridges "VMs were created" -> "VMs published their
#     codes". Triggered after the publisher's secrets exist AND after the
#     consumer's `vms_ready` value is known (the caller passes a VM name
#     output that resolves only after `data.google_compute_instance` has
#     refreshed against running VMs).
#   * One `data "google_secret_manager_secret_version"` per slot, gated on
#     the time_sleep. Failure here surfaces as "Error 404: Secret has no
#     versions" — the right loud signal that publishing didn't happen.
#
# Output `user_codes` is fed into `zpa_app_connector_group.user_codes`.
################################################################################

resource "time_sleep" "wait_for_publish" {
  create_duration = "${var.publish_wait_seconds}s"

  triggers = {
    # Re-run the wait if the slot set changes (e.g. vm_count grew). Without
    # this, on a subsequent apply with new slots Terraform might skip the
    # wait and try to read versions that don't exist yet.
    secret_ids = join(",", var.secret_ids)

    # Force the wait to start ONLY after the VMs exist. The caller passes
    # `module.ac_vm.ac_instance_names` (or equivalent) which is unknown
    # until VMs are created. Hashing it makes the trigger value stable
    # without leaking VM names into the trigger labels.
    vms_ready = sha1(jsonencode(var.vms_ready))

    # Same idea for secrets_ready — its presence in triggers means the
    # sleep can't start until the publisher's secrets and IAM exist.
    secrets_ready = sha1(jsonencode(var.secrets_ready))
  }
}

data "google_secret_manager_secret_version" "user_code" {
  count   = length(var.secret_ids)
  project = var.project
  secret  = var.secret_ids[count.index]
  version = "latest"

  depends_on = [time_sleep.wait_for_publish]
}
