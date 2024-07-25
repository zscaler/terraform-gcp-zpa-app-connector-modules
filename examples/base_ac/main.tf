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
# 2. Create Bastion Host for CC VM SSH jump access
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
# 3. Create ZPA App Connector Group
################################################################################
module "zpa_app_connector_group" {
  count                                        = var.byo_provisioning_key == true ? 0 : 1 # Only use this module if a new provisioning key is needed
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
  app_connector_group_version_profile_id       = var.app_connector_group_version_profile_id
  app_connector_group_dns_query_type           = var.app_connector_group_dns_query_type
}


################################################################################
# 4. Create ZPA Provisioning Key (or reference existing if byo set)
################################################################################
module "zpa_provisioning_key" {
  source                            = "../../modules/terraform-zpa-provisioning-key"
  enrollment_cert                   = var.enrollment_cert
  provisioning_key_name             = "${var.region}-${module.network.vpc_network_name}"
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  app_connector_group_id            = try(module.zpa_app_connector_group[0].app_connector_group_id, "")
  byo_provisioning_key              = var.byo_provisioning_key
  byo_provisioning_key_name         = var.byo_provisioning_key_name
}


################################################################################
# 5. Create specified number AC VMs per ac_count which will span equally across 
#    designated availability zones per az_count. E.g. ac_count set to 4 and 
#    az_count set to 2 will create 2x ACs in AZ1 and 2x ACs in AZ2
################################################################################
# Create the user_data file with necessary bootstrap variables for App Connector registration
locals {
  rhel9userdata = <<RHEL9USERDATA
#!/usr/bin/bash
# Sleep to allow the system to initialize
sleep 15

# Create the Zscaler repository file
touch /etc/yum.repos.d/zscaler.repo
cat > /etc/yum.repos.d/zscaler.repo <<-EOT
[zscaler]
name=Zscaler Private Access Repository
baseurl=https://yum.private.zscaler.com/yum/el9
enabled=1
gpgcheck=1
gpgkey=https://yum.private.zscaler.com/yum/el9/gpg
EOT

# Sleep to allow the repo file to be registered
sleep 60

# Install App Connector packages
yum install -y zpa-connector

# Stop the App Connector service which was auto-started at boot time
systemctl stop zpa-connector

# Create a file from the App Connector provisioning key created in the ZPA Admin Portal
# Make sure that the provisioning key is between double quotes
echo "${module.zpa_provisioning_key.provisioning_key}" > /opt/zscaler/var/provision_key
chmod 644 /opt/zscaler/var/provision_key

# Run a yum update to apply the latest patches
yum update -y

# Start the App Connector service to enroll it in the ZPA cloud
systemctl start zpa-connector

# Wait for the App Connector to download the latest build
sleep 60

# Stop and then start the App Connector for the latest build
systemctl stop zpa-connector
systemctl start zpa-connector
RHEL9USERDATA
}

# Write the file to local filesystem for storage/reference
resource "local_file" "user_data_file" {
  content  = local.rhel9userdata
  filename = "./user_data"
}


################################################################################
# Locate Latest Red Hat Enterprise Linux 9 AMI for instance use
################################################################################
data "google_compute_image" "zs_ac_img" {
  count   = var.image_name != "" ? 0 : 1
  family  = "rhel-9"
  project = "rhel-cloud"
}


################################################################################
# Query for active list of available zones for var.region
################################################################################
data "google_compute_zones" "available" {
  status = "UP"
}

locals {
  zones_list = length(var.zones) == 0 ? slice(data.google_compute_zones.available.names, 0, var.az_count) : distinct(var.zones)
}


################################################################################
# Create AC VM instances
################################################################################
module "ac_vm" {
  source              = "../../modules/terraform-zsac-acvm-gcp"
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  project             = var.project
  region              = var.region
  zones               = local.zones_list
  acvm_instance_type  = var.acvm_instance_type
  ssh_key             = tls_private_key.key.public_key_openssh
  user_data           = local.rhel9userdata
  ac_count            = var.ac_count
  acvm_vpc_subnetwork = module.network.ac_subnet
  image_name          = var.image_name != "" ? var.image_name : data.google_compute_image.zs_ac_img[0].self_link
}
