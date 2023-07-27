locals {
  testbedconfig = <<TB
### SSH to AC VM
1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}:/home/ubuntu/.

2) SSH to the AC VM bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}

3) SSH to the AC
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem admin@${module.ac_vm.ac_private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}"

All App Connector Instance IPs:
${join("\n", module.ac_vm.ac_private_ip)}


GCP Project Name:
${module.ac_vm.instance_template_project}

GCP Region:
${module.ac_vm.instance_template_region}

GCP VPC Network:
${module.network.vpc_network}

GCP Availability Zones:
${join("\n", module.ac_vm.instance_group_zones)}

Instance Group Names:
${join("\n", module.ac_vm.instance_group_names)}
TB
}

output "testbedconfig" {
  description = "Google Cloud Testbed results"
  value       = local.testbedconfig
}

resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "../testbed.txt"
}
