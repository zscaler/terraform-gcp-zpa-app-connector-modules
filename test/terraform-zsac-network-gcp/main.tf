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
  }
  required_version = ">= 0.13.7, < 2.0.0"
}

# project / region come from TF_VAR_project / TF_VAR_region (set by the
# Makefile from $PROJECT_ID / $REGION env vars). GCP credentials come from
# Application Default Credentials (or GOOGLE_APPLICATION_CREDENTIALS).
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

locals {
  name_prefix  = local.prefix
  resource_tag = random_pet.this.id
}

################################################################################
# Module under test
################################################################################
module "network" {
  source = "../../modules/terraform-zsac-network-gcp"

  name_prefix                    = local.name_prefix
  resource_tag                   = local.resource_tag
  project                        = var.project
  region                         = var.region
  subnet_bastion                 = var.subnet_bastion
  subnet_ac                      = var.subnet_ac
  bastion_enabled                = var.bastion_enabled
  allowed_ssh_from_internal_cidr = [var.subnet_bastion]
  allowed_ports                  = var.allowed_ports
  routing_mode                   = var.routing_mode
}
