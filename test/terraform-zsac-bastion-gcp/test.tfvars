# Test inputs for terraform-zsac-bastion-gcp.
# project + region come from TF_VAR_project / TF_VAR_region (set by Makefile).
# zone is left null so the provider picks <region>-a.
bastion_ssh_allow_ip = ["0.0.0.0/0"]
