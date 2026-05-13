################################################################################
# OAuth user-code PUBLISHER half of the OAuth onboarding flow.
#
# Owns:
#   * One Secret Manager secret per VM slot.
#   * IAM bindings letting the VM service account add versions and read.
#   * Renders the bash script the VMs run on first boot to publish their
#     OAuth code into their assigned secret slot.
#
# Does NOT read secret versions — that's the reader module's job. The split
# matters because if reader (which owns the time_sleep + data sources) lived
# here, anything that consumed user_data would transitively depend on
# time_sleep, blocking VM creation until after the sleep finished — at which
# point the sleep window would have expired with no VMs to publish.
################################################################################

locals {
  secret_ids = [for i in range(var.vm_count) : "${var.name_prefix}-${var.resource_tag}-zpa-user-code-${i}"]
}

resource "google_secret_manager_secret" "user_code" {
  count     = var.vm_count
  project   = var.project
  secret_id = local.secret_ids[count.index]

  replication {
    auto {}
  }

  labels = {
    managed-by = "terraform-zpa-app-connector"
    purpose    = "zpa-oauth-user-code"
  }
}

resource "google_secret_manager_secret_iam_member" "vm_publisher" {
  count     = var.vm_count
  project   = google_secret_manager_secret.user_code[count.index].project
  secret_id = google_secret_manager_secret.user_code[count.index].secret_id
  role      = "roles/secretmanager.secretVersionAdder"
  member    = "serviceAccount:${var.service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "vm_accessor" {
  count     = var.vm_count
  project   = google_secret_manager_secret.user_code[count.index].project
  secret_id = google_secret_manager_secret.user_code[count.index].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}
