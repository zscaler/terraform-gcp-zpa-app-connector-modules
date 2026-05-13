################################################################################
# Generate a unique random string for resource name assignment and key pair
################################################################################
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}


################################################################################
# The following lines generates a new SSH key pair and stores the PEM file
# locally. The public key output is used as the ssh_key passed variable
# to the compute modules for admin_ssh_key public_key authentication.
# This is not recommended for production deployments. Please consider modifying
# to pass your own custom public key file located in a secure location.
################################################################################
resource "tls_private_key" "key" {
  algorithm = var.tls_key_algorithm
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "./${var.name_prefix}-key-${random_string.suffix.result}.pem"
  file_permission = "0600"
}


################################################################################
# CYCLE-BREAKING NOTE FOR THIS FILE
#
# We split the connector group into two count-gated calls (`_oauth` and
# `_legacy`) because Terraform builds its dependency graph from textual
# references and does NOT collapse conditionals — `var.x ? a : b` records
# edges to BOTH branches. With a single connector group, the OAuth path
# (group depends on user_codes from secret-manager-data; secret-manager-data
# depends on VMs; VMs depend on user_data) AND the legacy path (group
# referenced by provisioning_key; provisioning_key referenced by user_data
# locals) collapse into a cycle.
#
# Splitting into `_oauth` (count=1 in OAuth mode, references user_code module)
# and `_legacy` (count=1 in legacy mode, referenced by provisioning_key) means
# that in either mode exactly one of the two has count>0. Splat references
# (`module.X[*]...` resolved with `one()`) yield empty lists in the inactive
# mode so no live edge is recorded.
################################################################################


################################################################################
# 1. Create/reference all network infrastructure resource dependencies for all
#    child modules (vpc, router, nat gateway, subnets)
################################################################################
module "network" {
  source                         = "../../modules/terraform-zsac-network-gcp"
  name_prefix                    = var.name_prefix
  resource_tag                   = random_string.suffix.result
  project                        = var.project
  region                         = var.region
  allowed_ssh_from_internal_cidr = [var.subnet_bastion]
  allowed_ports                  = var.allowed_ports

  subnet_bastion = var.subnet_bastion
  subnet_ac      = var.subnet_ac

  bastion_enabled = true
}


################################################################################
# 2. Create Bastion Host for AC VM SSH jump access
################################################################################
module "bastion" {
  source               = "../../modules/terraform-zsac-bastion-gcp"
  name_prefix          = var.name_prefix
  resource_tag         = random_string.suffix.result
  public_subnet        = module.network.bastion_subnet[0]
  zone                 = length(var.zones) == 0 ? data.google_compute_zones.available.names[0] : var.zones[0]
  ssh_key              = tls_private_key.key.public_key_openssh
  vpc_network          = module.network.vpc_network
  bastion_ssh_allow_ip = var.bastion_ssh_allow_ip
}


################################################################################
# 3. (OAuth path) Provision a service account for the App Connector VMs and
#    instantiate the user-code module. The SA needs Secret Manager write/read
#    on the per-VM secret slots that the module pre-creates. The acvm module
#    attaches the same SA to the VMs so the templated startup script can
#    publish to its assigned slot.
################################################################################
resource "google_service_account" "ac_vm" {
  count        = var.use_user_code_method ? 1 : 0
  project      = var.project
  account_id   = "${var.name_prefix}-acvm-${random_string.suffix.result}"
  display_name = "ZPA App Connector VM SA (${var.name_prefix}-${random_string.suffix.result})"
  description  = "Used by App Connector VMs to publish OAuth enrollment codes to Secret Manager."
}

module "user_code_publisher" {
  count                 = var.use_user_code_method ? 1 : 0
  source                = "../../modules/terraform-zpa-user-code-publisher"
  name_prefix           = var.name_prefix
  resource_tag          = random_string.suffix.result
  project               = var.project
  vm_count              = var.ac_count * length(local.zones_list)
  service_account_email = google_service_account.ac_vm[0].email
}


################################################################################
# 4. Create ZPA Provisioning Key (legacy path only).
#    Sources the connector group ID from the splat of the legacy connector
#    group (see the cycle-breaking note at the top of this file).
################################################################################
module "zpa_provisioning_key" {
  count                             = var.use_user_code_method ? 0 : 1
  source                            = "../../modules/terraform-zpa-provisioning-key"
  provisioning_key_name             = "${var.region}-${module.network.vpc_network_name}"
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  app_connector_group_id            = one(module.zpa_app_connector_group_legacy[*].app_connector_group_id)
  byo_provisioning_key              = var.byo_provisioning_key
  byo_provisioning_key_name         = var.byo_provisioning_key_name
}


################################################################################
# 5. Render user_data. Two distinct flows depending on use_user_code_method.
#    Legacy locals reference provisioning_key via splat-and-one() so that in
#    OAuth mode (where the provisioning_key has count=0) Terraform can resolve
#    the textual reference to an empty splat and not record a graph edge.
################################################################################
locals {
  # In OAuth mode the user_code module has count=1; in legacy mode count=0
  # and the splat resolves to empty, so the placeholder is what we'd render
  # — but effective_user_data picks the legacy heredoc in that case so the
  # placeholder is never delivered.
  oauth_user_data = coalesce(one(module.user_code_publisher[*].user_data), "OAUTH_USER_DATA_NOT_SET")

  # Same dance the other way: pk_value is referenced inside the legacy
  # heredocs. In OAuth mode the provisioning_key module has count=0; we
  # coalesce so locals evaluate cleanly even though the heredoc is never
  # delivered to a VM.
  pk_value = coalesce(one(module.zpa_provisioning_key[*].provisioning_key), "PROVISIONING_KEY_NOT_SET")

  provkey_user_data_zscaler_image = <<APPUSERDATA
#!/bin/bash
#Stop the App Connector service which was auto-started at boot time
systemctl stop zpa-connector
#Create a file from the App Connector provisioning key created in the ZPA Admin Portal
#Make sure that the provisioning key is between double quotes
echo "${local.pk_value}" > /opt/zscaler/var/provision_key

#Run a yum update to apply the latest patches
yum update -y

#Start the App Connector service to enroll it in the ZPA cloud
systemctl start zpa-connector

#Wait for the App Connector to download latest build
sleep 60

#Stop and then start the App Connector for the latest build
systemctl stop zpa-connector
systemctl start zpa-connector
APPUSERDATA

  provkey_user_data_rhel9 = <<RHEL9USERDATA
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
echo "${local.pk_value}" > /opt/zscaler/var/provision_key
chmod 644 /opt/zscaler/var/provision_key
yum update -y
systemctl start zpa-connector
sleep 60
systemctl stop zpa-connector
systemctl start zpa-connector
RHEL9USERDATA

  provkey_user_data = var.use_zscaler_image ? local.provkey_user_data_zscaler_image : local.provkey_user_data_rhel9

  effective_user_data = var.use_user_code_method ? local.oauth_user_data : local.provkey_user_data
}

resource "local_file" "user_data_file" {
  content  = local.effective_user_data
  filename = "./user_data"
}


################################################################################
# 6. Locate the appropriate base image.
################################################################################
data "google_compute_image" "appconnector" {
  count   = var.use_zscaler_image ? 1 : 0
  project = "mpi-zpa-gcp-marketplace"
  name    = "zpa-connector-el9-2025-11"
}

data "google_compute_image" "rhel_9_latest" {
  count   = var.image_name != "" ? 0 : 1
  family  = "rhel-9"
  project = "rhel-cloud"
}

locals {
  image_selected = try(data.google_compute_image.appconnector[0].self_link, data.google_compute_image.rhel_9_latest[0].self_link)
}


################################################################################
# 7. Pick zones to deploy into.
################################################################################
data "google_compute_zones" "available" {
  status = "UP"
}

locals {
  zones_list = length(var.zones) == 0 ? slice(data.google_compute_zones.available.names, 0, var.az_count) : distinct(var.zones)
}


################################################################################
# 8. Create AC VM instances. The VMs run effective_user_data on first boot.
################################################################################
module "ac_vm" {
  source                = "../../modules/terraform-zsac-acvm-gcp"
  name_prefix           = var.name_prefix
  resource_tag          = random_string.suffix.result
  project               = var.project
  region                = var.region
  zones                 = local.zones_list
  acvm_instance_type    = var.acvm_instance_type
  ssh_key               = tls_private_key.key.public_key_openssh
  user_data             = local.effective_user_data
  ac_count              = var.ac_count
  acvm_vpc_subnetwork   = module.network.ac_subnet
  image_name            = var.image_name != "" ? var.image_name : local.image_selected
  service_account_email = one(google_service_account.ac_vm[*].email)
}


################################################################################
# 9. (OAuth path) Read the OAuth codes back from Secret Manager once the VMs
#    have had time to publish. The reader's time_sleep is gated on
#    `vms_ready` so it can't start until VMs exist; we feed it a value that
#    only resolves after `data "google_compute_instance"` refreshes.
################################################################################
module "user_code_reader" {
  count         = var.use_user_code_method ? 1 : 0
  source        = "../../modules/terraform-zpa-user-code-reader"
  project       = var.project
  secret_ids    = module.user_code_publisher[0].secret_ids
  secrets_ready = module.user_code_publisher[0].secrets_ready
  vms_ready     = module.ac_vm.ac_instance_names
}


################################################################################
# 10a. (OAuth path) Create the App Connector Group with the resolved codes.
################################################################################
module "zpa_app_connector_group_oauth" {
  count                                        = var.use_user_code_method ? 1 : 0
  source                                       = "../../modules/terraform-zpa-app-connector-group"
  app_connector_group_name                     = "${var.region}-${module.network.vpc_network_name}"
  app_connector_group_description              = "${var.app_connector_group_description}-${var.region}-${module.network.vpc_network_name}"
  app_connector_group_enabled                  = var.app_connector_group_enabled
  app_connector_group_country_code             = var.app_connector_group_country_code
  app_connector_group_latitude                 = var.app_connector_group_latitude
  app_connector_group_longitude                = var.app_connector_group_longitude
  app_connector_group_location                 = var.app_connector_group_location
  app_connector_group_upgrade_day              = var.app_connector_group_upgrade_day
  app_connector_group_upgrade_time_in_secs     = var.app_connector_group_upgrade_time_in_secs
  app_connector_group_override_version_profile = var.app_connector_group_override_version_profile
  app_connector_group_dns_query_type           = var.app_connector_group_dns_query_type

  user_codes = module.user_code_reader[0].user_codes
}


################################################################################
# 10b. (Legacy path) Create the App Connector Group with no user_codes.
#      Count-gated so the provisioning_key -> group edge only exists in legacy
#      mode.
################################################################################
module "zpa_app_connector_group_legacy" {
  count                                        = var.use_user_code_method ? 0 : 1
  source                                       = "../../modules/terraform-zpa-app-connector-group"
  app_connector_group_name                     = "${var.region}-${module.network.vpc_network_name}"
  app_connector_group_description              = "${var.app_connector_group_description}-${var.region}-${module.network.vpc_network_name}"
  app_connector_group_enabled                  = var.app_connector_group_enabled
  app_connector_group_country_code             = var.app_connector_group_country_code
  app_connector_group_latitude                 = var.app_connector_group_latitude
  app_connector_group_longitude                = var.app_connector_group_longitude
  app_connector_group_location                 = var.app_connector_group_location
  app_connector_group_upgrade_day              = var.app_connector_group_upgrade_day
  app_connector_group_upgrade_time_in_secs     = var.app_connector_group_upgrade_time_in_secs
  app_connector_group_override_version_profile = var.app_connector_group_override_version_profile
  app_connector_group_dns_query_type           = var.app_connector_group_dns_query_type

  user_codes = []
}
