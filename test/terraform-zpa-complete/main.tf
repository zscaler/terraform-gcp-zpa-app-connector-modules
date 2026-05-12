################################################################################
# End-to-end test fixture wrapping examples/base_ac.
#
# This composes the same six modules a real user would when they run
# `terraform apply` inside examples/base_ac, but parameterised for the test
# tenant. Required env:
#   ZSCALER_CLIENT_ID, ZSCALER_CLIENT_SECRET, ZSCALER_VANITY_DOMAIN,
#   ZSCALER_CLOUD (optional), ZPA_CUSTOMER_ID, PROJECT_ID
#
# We deliberately copy the example's wiring rather than `module { source =
# "../../examples/base_ac" }` because Terraform warns when a child module
# carries its own provider block, and that pattern is brittle against future
# example refactors.
################################################################################
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.31.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.8.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2.0"
    }
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 4.4.0"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "zpa" {}

# See test/terraform-zpa-app-connector-group/main.tf for naming convention.
locals {
  prefix = var.pr_id != "" ? "ghcip${var.pr_id}" : "ghcitt"
}

resource "random_pet" "this" {
  prefix = local.prefix
  length = 1
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

locals {
  name_prefix  = local.prefix
  resource_tag = random_pet.this.id
}

################################################################################
# 1. Network
################################################################################
module "network" {
  source = "../../modules/terraform-zsac-network-gcp"

  name_prefix                    = local.name_prefix
  resource_tag                   = local.resource_tag
  project                        = var.project
  region                         = var.region
  allowed_ssh_from_internal_cidr = [var.subnet_bastion]
  allowed_ports                  = var.allowed_ports
  subnet_bastion                 = var.subnet_bastion
  subnet_ac                      = var.subnet_ac
  bastion_enabled                = true
}

################################################################################
# 2. Bastion
################################################################################
module "bastion" {
  source = "../../modules/terraform-zsac-bastion-gcp"

  name_prefix          = local.name_prefix
  resource_tag         = local.resource_tag
  public_subnet        = module.network.bastion_subnet[0]
  zone                 = data.google_compute_zones.available.names[0]
  ssh_key              = tls_private_key.key.public_key_openssh
  vpc_network          = module.network.vpc_network
  bastion_ssh_allow_ip = var.bastion_ssh_allow_ip
}

################################################################################
# 3. ZPA App Connector Group
################################################################################
module "zpa_app_connector_group" {
  source = "../../modules/terraform-zpa-app-connector-group"

  app_connector_group_name         = "${var.region}-${module.network.vpc_network_name}"
  app_connector_group_description  = "terratest fixture - ${local.resource_tag}"
  app_connector_group_enabled      = true
  app_connector_group_country_code = "US"
  app_connector_group_latitude     = "37.33874"
  app_connector_group_longitude    = "-121.8852525"
  app_connector_group_location     = "San Jose, CA, USA"
}

################################################################################
# 4. ZPA Provisioning Key
################################################################################
module "zpa_provisioning_key" {
  source = "../../modules/terraform-zpa-provisioning-key"

  provisioning_key_name      = "${var.region}-${module.network.vpc_network_name}"
  provisioning_key_max_usage = 10
  app_connector_group_id     = module.zpa_app_connector_group.app_connector_group_id
}

################################################################################
# 5. App Connector VM(s)
#
# Use the latest RHEL 9 image so this fixture works in tenants that do not
# have access to the Zscaler marketplace project.
################################################################################
data "google_compute_image" "rhel_9_latest" {
  family  = "rhel-9"
  project = "rhel-cloud"
}

data "google_compute_zones" "available" {
  status = "UP"
}

locals {
  zones_list = slice(data.google_compute_zones.available.names, 0, var.az_count)

  # Real bootstrap script: same shape as examples/base_ac so the test
  # exercises the actual provisioning-key wiring end-to-end.
  user_data = <<USERDATA
#!/usr/bin/bash
sleep 15
touch /etc/yum.repos.d/zscaler.repo
cat > /etc/yum.repos.d/zscaler.repo <<-EOT
[zscaler]
name=Zscaler Private Access Repository
baseurl=https://yum.private.zscaler.com/yum/el9
enabled=1
gpgcheck=1
gpgkey=https://yum.private.zscaler.com/yum/el9/gpg
EOT
sleep 60
yum install -y zpa-connector
systemctl stop zpa-connector
echo "${module.zpa_provisioning_key.provisioning_key}" > /opt/zscaler/var/provision_key
chmod 644 /opt/zscaler/var/provision_key
yum update -y
systemctl start zpa-connector
sleep 60
systemctl stop zpa-connector
systemctl start zpa-connector
USERDATA
}

module "ac_vm" {
  source = "../../modules/terraform-zsac-acvm-gcp"

  name_prefix         = local.name_prefix
  resource_tag        = local.resource_tag
  project             = var.project
  region              = var.region
  zones               = local.zones_list
  acvm_instance_type  = var.acvm_instance_type
  ssh_key             = tls_private_key.key.public_key_openssh
  user_data           = local.user_data
  ac_count            = var.ac_count
  acvm_vpc_subnetwork = module.network.ac_subnet
  image_name          = data.google_compute_image.rhel_9_latest.self_link
}
