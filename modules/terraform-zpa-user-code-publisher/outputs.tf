output "user_data" {
  description = "Rendered VM startup script. Pass to the acvm/asg module's `user_data` variable. The script reads /etc/issue, finds the OAuth code, and writes it to its assigned Secret Manager secret slot."
  value = templatefile("${path.module}/scripts/publish_user_code.sh.tftpl", {
    secret_ids_bash  = join(" ", [for id in local.secret_ids : format("%q", id)])
    project          = var.project
    max_wait_seconds = var.max_wait_seconds
  })
}

output "secret_ids" {
  description = "Names of the Secret Manager secrets created for each VM slot. Pass to the user-code-reader module so it knows which secrets to read back."
  value       = local.secret_ids
}

output "secrets_ready" {
  description = "Sentinel value (a list of secret resource ids) that downstream resources can use as a `depends_on` to ensure secrets and their IAM bindings exist before the dependent resource is created. Used by the reader module to gate its time_sleep on real secret existence."
  value = [
    for s in google_secret_manager_secret.user_code : s.id
  ]
  depends_on = [
    google_secret_manager_secret_iam_member.vm_publisher,
    google_secret_manager_secret_iam_member.vm_accessor,
  ]
}
