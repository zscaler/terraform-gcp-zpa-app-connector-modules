# Test inputs for terraform-zsac-asg-gcp.
# project + region come from TF_VAR_project / TF_VAR_region (set by Makefile).
az_count               = 1
acvm_instance_type     = "n2-standard-4"
min_size               = 1
max_size               = 2
target_tracking_metric = "ASGAverageCPUUtilization"
target_cpu_util_value  = 50
