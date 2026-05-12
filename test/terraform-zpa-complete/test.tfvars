# End-to-end test inputs.
# project + region come from TF_VAR_project / TF_VAR_region (set by Makefile).
az_count             = 1
ac_count             = 1
acvm_instance_type   = "n2-standard-4"
subnet_bastion       = "10.0.0.0/24"
subnet_ac            = "10.0.1.0/24"
bastion_ssh_allow_ip = ["0.0.0.0/0"]
allowed_ports        = []
