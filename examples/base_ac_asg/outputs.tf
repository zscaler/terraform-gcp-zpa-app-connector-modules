locals {
  testbedconfig = <<TB
### Bastion / SSH access
1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}:/home/ubuntu/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}

3) From the bastion, find a current AC instance via the GCP console / gcloud:
   gcloud compute instances list --filter="name~'${var.name_prefix}-ac-asg-'"

4) SSH from bastion to a chosen AC instance using its private IP:
   ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem admin@<AC-PRIVATE-IP>

(Note: per-instance IPs are NOT exported because the autoscaler can replace
instances at any time. Always discover them dynamically.)


### Autoscaling group(s)

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
