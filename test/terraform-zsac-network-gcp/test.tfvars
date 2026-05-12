# Test inputs for terraform-zsac-network-gcp.
# project + region come from TF_VAR_project / TF_VAR_region (set by Makefile).
subnet_bastion  = "10.0.0.0/24"
subnet_ac       = "10.0.1.0/24"
bastion_enabled = true
allowed_ports   = []
routing_mode    = "REGIONAL"
