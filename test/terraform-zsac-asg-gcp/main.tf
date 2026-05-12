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

  user_data = "#!/bin/bash\necho 'terratest-fixture' > /tmp/zsac-test-marker\n"
}

################################################################################
# Dependencies
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

data "google_compute_image" "rhel_9_latest" {
  family  = "rhel-9"
  project = "rhel-cloud"
}

data "google_compute_zones" "available" {
  status = "UP"
}

locals {
  zones_list = slice(data.google_compute_zones.available.names, 0, var.az_count)
}

################################################################################
# Module under test
################################################################################
module "ac_asg" {
  source = "../../modules/terraform-zsac-asg-gcp"

  name_prefix            = local.name_prefix
  resource_tag           = local.resource_tag
  project                = var.project
  region                 = var.region
  zones                  = local.zones_list
  acvm_instance_type     = var.acvm_instance_type
  ssh_key                = tls_private_key.key.public_key_openssh
  user_data              = local.user_data
  acvm_vpc_subnetwork    = module.network.ac_subnet
  image_name             = data.google_compute_image.rhel_9_latest.self_link
  min_size               = var.min_size
  max_size               = var.max_size
  target_tracking_metric = var.target_tracking_metric
  target_cpu_util_value  = var.target_cpu_util_value
}
