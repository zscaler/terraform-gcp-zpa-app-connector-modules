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
# See examples/ac/main.tf for the full explanation. tl;dr:
#   - connector_group is split into _oauth and _legacy, each count-gated.
#   - provisioning_key references group_legacy[*] via splat (only live in legacy).
#   - legacy user_data references provisioning_key[*] via splat (only live in legacy).
#   - resolver references ac_asg (only live in OAuth).
# Result: each mode has a clean DAG with no cycle.
################################################################################


################################################################################
# 1. Create/reference all network infrastructure. Greenfield variant — bastion
#    subnet is created so a bastion host can jump into the ASG VMs.
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
# 3. (OAuth path) Provision a service account for App Connector ASG VMs and
#    instantiate the user-code module.
#
#    For ASG, vm_count is sized to max_size so the autoscaler has spare slots
#    to claim on scale-out. Each VM picks the first unused slot at boot. If
#    you bump max_size, run `terraform apply` again to provision more slots
#    AND to read back the codes published by any newly-launched VMs.
################################################################################
resource "google_service_account" "ac_vm" {
  count        = var.use_user_code_method ? 1 : 0
  project      = var.project
  account_id   = "${var.name_prefix}-acvm-${random_string.suffix.result}"
  display_name = "ZPA App Connector VM SA (${var.name_prefix}-${random_string.suffix.result})"
  description  = "Used by App Connector ASG VMs to publish OAuth enrollment codes to Secret Manager."
}

module "user_code_publisher" {
  count        = var.use_user_code_method ? 1 : 0
  source       = "../../modules/terraform-zpa-user-code-publisher"
  name_prefix  = var.name_prefix
  resource_tag = random_string.suffix.result
  project      = var.project
  # Only pre-create slots for the VMs guaranteed to be running at apply
  # time (the min_size guarantees from each zonal MIG). If you scale the
  # ASG up by changing min_size or max_size, re-run `terraform apply`
  # AFTER the new VMs are healthy to expand vm_count and pick up their
  # codes; otherwise the data sources for unfilled slots will fail with
  # "secret has no versions" and the group will reject enrollment.
  vm_count              = var.min_size * length(local.zones_list)
  service_account_email = google_service_account.ac_vm[0].email
}


################################################################################
# 4. Create ZPA Provisioning Key (legacy path only).
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
################################################################################
locals {
  oauth_user_data = coalesce(one(module.user_code_publisher[*].user_data), "OAUTH_USER_DATA_NOT_SET")

  # See examples/ac/main.tf for the rationale on this coalesce. In OAuth mode
  # pk has count=0 and the splat is empty; the placeholder string is never
  # actually delivered to a VM because effective_user_data picks the OAuth
  # path.
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
# 8. Create the App Connector autoscaling group(s).
################################################################################
module "ac_asg" {
  source                = "../../modules/terraform-zsac-asg-gcp"
  name_prefix           = var.name_prefix
  resource_tag          = random_string.suffix.result
  project               = var.project
  region                = var.region
  zones                 = local.zones_list
  acvm_instance_type    = var.acvm_instance_type
  ssh_key               = tls_private_key.key.public_key_openssh
  user_data             = local.effective_user_data
  acvm_vpc_subnetwork   = module.network.ac_subnet
  image_name            = var.image_name != "" ? var.image_name : local.image_selected
  service_account_email = one(google_service_account.ac_vm[*].email)

  min_size                  = var.min_size
  max_size                  = var.max_size
  target_tracking_metric    = var.target_tracking_metric
  target_cpu_util_value     = var.target_cpu_util_value
  cooldown_period           = var.cooldown_period
  health_check_grace_period = var.health_check_grace_period
}


################################################################################
# 9. (OAuth path) Read OAuth codes from Secret Manager once VMs publish.
#    `vms_ready` references the ASG output that lists running VMs at apply
#    time, so the time_sleep can't start before VMs exist.
#
#    ASG caveat: vm_count is sized to min_size; new VMs from a scale-out
#    publish into unallocated slot range and won't enroll. Re-run
#    `terraform apply` after a scale-out event to allocate slots and re-
#    read codes.
################################################################################
module "user_code_reader" {
  count         = var.use_user_code_method ? 1 : 0
  source        = "../../modules/terraform-zpa-user-code-reader"
  project       = var.project
  secret_ids    = module.user_code_publisher[0].secret_ids
  secrets_ready = module.user_code_publisher[0].secrets_ready
  vms_ready     = module.ac_asg.running_instance_names
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
