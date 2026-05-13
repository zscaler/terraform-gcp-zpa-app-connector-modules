locals {
  testbedconfig = <<TB
### Brownfield ASG deployment summary

GCP Project Name:
${module.ac_asg.instance_template_project}

GCP Region:
${module.ac_asg.instance_template_region}

GCP VPC Network:
${module.network.vpc_network}

GCP Availability Zones:
${join("\n", module.ac_asg.instance_group_zones)}

Managed Instance Group Names (one per zone):
${join("\n", module.ac_asg.instance_group_names)}

Autoscaler Names (one per zone):
${join("\n", module.ac_asg.autoscaler_names)}

Sizing:
  min per zone : ${var.min_size}
  max per zone : ${var.max_size}
  metric       : ${var.target_tracking_metric}
  target value : ${var.target_cpu_util_value}

### Reaching App Connector instances

Brownfield deploys do NOT include a bastion host. Use your existing
jump-host / IAP tunnel / Cloud Identity-aware proxy to reach instances:

  gcloud compute instances list --filter="name~'${var.name_prefix}-ac-asg-'"
  gcloud compute ssh <instance-name> --tunnel-through-iap

Per-instance IPs are NOT exported because the autoscaler can replace
instances at any time. Always discover them dynamically.
TB
}

output "testbedconfig" {
  description = "Google Cloud Testbed results"
  value       = local.testbedconfig
}

resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "./testbed.txt"
}
