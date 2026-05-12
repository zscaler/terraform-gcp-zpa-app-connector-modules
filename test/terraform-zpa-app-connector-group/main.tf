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

# All ZPA OneAPI credentials are read from the environment by the provider:
#   ZSCALER_CLIENT_ID, ZSCALER_CLIENT_SECRET, ZSCALER_VANITY_DOMAIN,
#   ZSCALER_CLOUD (optional), ZPA_CUSTOMER_ID
provider "zpa" {}

# Resource naming convention (mirrors Palo Alto's swfw modules so the shared
# .github/actions/gcp_cleanup script can find orphans):
#   * PR run:        ghcip<PR_ID>-<random>
#   * Release / cron:ghcitt-<random>
# `pr_id` is set by .github/actions/terratest/action.yml via TF_VAR_pr_id
# from the workflow's pr-id input. When unset (local `make` run) we fall back
# to the `ghcitt` prefix so a developer running TestApply manually still gets
# a name the cleanup script will sweep.
locals {
  prefix = var.pr_id != "" ? "ghcip${var.pr_id}" : "ghcitt"
}

# Random suffix lets multiple PRs run in parallel against the same tenant.
# length=1 keeps total resource names under GCP's 63-char limit.
resource "random_pet" "this" {
  prefix = local.prefix
  length = 1
}

################################################################################
# Module under test
################################################################################
module "app_connector_group" {
  source = "../../modules/terraform-zpa-app-connector-group"

  app_connector_group_name         = random_pet.this.id
  app_connector_group_description  = "terratest fixture - safe to delete"
  app_connector_group_enabled      = var.app_connector_group_enabled
  app_connector_group_latitude     = var.app_connector_group_latitude
  app_connector_group_longitude    = var.app_connector_group_longitude
  app_connector_group_location     = var.app_connector_group_location
  app_connector_group_country_code = var.app_connector_group_country_code
}
