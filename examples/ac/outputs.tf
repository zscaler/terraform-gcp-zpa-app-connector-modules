locals {
  testbedconfig = <<TB
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

All App Connector Instance IPs:
${join("\n", module.ac_vm.ac_private_ip)}
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
