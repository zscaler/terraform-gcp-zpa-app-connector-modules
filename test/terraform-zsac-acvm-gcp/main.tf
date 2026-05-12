################################################################################
# Provider configuration
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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2.0"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}

provider "google" {
  project = var.project
  region  = var.region
}

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

  # Minimal placeholder user-data. Real provisioning would echo a ZPA key into
  # /opt/zscaler/var/provision_key; for the module test we only need the field
  # to be populated. The instance will boot but won't successfully enroll.
  user_data = "#!/bin/bash\necho 'terratest-fixture' > /tmp/zsac-test-marker\n"
}

################################################################################
# Dependencies: a network for the VMs to attach to.
################################################################################
module "network" {
  source = "../../modules/terraform-zsac-network-gcp"

  name_prefix                    = local.name_prefix
  resource_tag                   = local.resource_tag
  project                        = var.project
  region                         = var.region
  bastion_enabled                = false
  allowed_ssh_from_internal_cidr = ["10.0.0.0/24"]
  allowed_ports                  = []
}

# Pull the most recent RHEL 9 image so the test does not depend on access to
# the Zscaler marketplace project (which not every test tenant can read).
data "google_compute_image" "rhel_9_latest" {
  family  = "rhel-9"
  project = "rhel-cloud"
}

# Discover available zones in the test region instead of hard-coding them.
data "google_compute_zones" "available" {
  status = "UP"
}

locals {
  zones_list = slice(data.google_compute_zones.available.names, 0, var.az_count)
}

################################################################################
# Module under test
################################################################################
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
