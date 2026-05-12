################################################################################
# Provider configuration
################################################################################
terraform {
  required_providers {
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 4.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}

# All ZPA OneAPI credentials are read from the environment by the provider
# (ZSCALER_CLIENT_ID, ZSCALER_CLIENT_SECRET, ZSCALER_VANITY_DOMAIN,
#  ZSCALER_CLOUD optional, ZPA_CUSTOMER_ID).
provider "zpa" {}

# See test/terraform-zpa-app-connector-group/main.tf for naming convention.
locals {
  prefix = var.pr_id != "" ? "ghcip${var.pr_id}" : "ghcitt"
}

resource "random_pet" "this" {
  prefix = local.prefix
  length = 1
}

################################################################################
# Dependency: an App Connector Group to attach the provisioning key to. We
# include the sister module here rather than mocking the ID so that the test
# also catches any wiring drift between the two modules.
################################################################################
module "app_connector_group" {
  source = "../../modules/terraform-zpa-app-connector-group"

  app_connector_group_name         = random_pet.this.id
  app_connector_group_description  = "terratest fixture - safe to delete"
  app_connector_group_latitude     = "37.33874"
  app_connector_group_longitude    = "-121.8852525"
  app_connector_group_location     = "San Jose, CA, USA"
  app_connector_group_country_code = "US"
}

################################################################################
# Module under test
################################################################################
module "provisioning_key" {
  source = "../../modules/terraform-zpa-provisioning-key"

  provisioning_key_name             = random_pet.this.id
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  app_connector_group_id            = module.app_connector_group.app_connector_group_id
}
