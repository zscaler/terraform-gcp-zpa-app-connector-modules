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

# Generate an ephemeral key pair for the bastion. Discarded with the test.
resource "tls_private_key" "key" {
  algorithm = "RSA"
}

locals {
  name_prefix  = local.prefix
  resource_tag = random_pet.this.id
}

################################################################################
# Dependency: a network for the bastion to attach to. We reuse the network
# module here rather than crafting a hand-built subnet so the test also catches
# wiring drift between network <-> bastion.
################################################################################
module "network" {
  source = "../../modules/terraform-zsac-network-gcp"

  name_prefix                    = local.name_prefix
  resource_tag                   = local.resource_tag
  project                        = var.project
  region                         = var.region
  bastion_enabled                = true
  allowed_ssh_from_internal_cidr = ["10.0.0.0/24"]
  allowed_ports                  = []
}

################################################################################
# Module under test
################################################################################
module "bastion" {
  source = "../../modules/terraform-zsac-bastion-gcp"

  name_prefix          = local.name_prefix
  resource_tag         = local.resource_tag
  public_subnet        = module.network.bastion_subnet[0]
  vpc_network          = module.network.vpc_network
  ssh_key              = tls_private_key.key.public_key_openssh
  zone                 = var.zone
  bastion_ssh_allow_ip = var.bastion_ssh_allow_ip
}
