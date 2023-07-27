## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment

## Variables are populated automically if terraform is ran via ZSEC bash script.
## Modifying the variables in this file will override any inputs from ZSEC.


#####################################################################################################################
##### Optional: ZPA Provider Resources. Skip to step 3. if you already have an  #####
##### App Connector Group + Provisioning Key.                                   #####
#####################################################################################################################

## 1. ZPA App Connector Provisioning Key variables. Uncomment and replace default values as desired for your deployment.
##    For any questions populating the below values, please reference:
##    https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_provisioning_key

#enrollment_cert                                = "Connector"
#provisioning_key_name                          = "new_key_name"
#provisioning_key_enabled                       = true
#provisioning_key_max_usage                     = 10

## 2. ZPA App Connector Group variables. Uncomment and replace default values as desired for your deployment.
##    For any questions populating the below values, please reference:
##    https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_app_connector_group

#app_connector_group_name                       = "new_group_name"
#app_connector_group_description                = "group_description"
#app_connector_group_enabled                    = true
#app_connector_group_country_code               = "US"
#app_connector_group_latitude                   = "37.3382082"
#app_connector_group_longitude                  = "-121.8863286"
#app_connector_group_location                   = "San Jose, CA, USA"
#app_connector_group_upgrade_day                = "SUNDAY"
#app_connector_group_upgrade_time_in_secs       = "66600"
#app_connector_group_override_version_profile   = true
#app_connector_group_version_profile_id         = "2"
#app_connector_group_dns_query_type             = "IPV4_IPV6"


#####################################################################################################################
##### Optional: ZPA Provider Resources. Skip to step 5. if you added values for steps 1. and 2. #####
##### meaning you do NOT have a provisioning key already.                                       #####
#####################################################################################################################

## 3. By default, this script will create a new App Connector Group Provisioning Key.
##     Uncomment if you want to use an existing provisioning key (true or false. Default: false)

#byo_provisioning_key                           = true

## 4. Provide your existing provisioning key name. Only uncomment and modify if yo uset byo_provisioning_key to true

#byo_provisioning_key_name                      = "example-key-name"


#####################################################################################################################
##### Terraform/Cloud Environment variables  #####
#####################################################################################################################
## 5. GCP region where App Connector resources will be deployed. This environment variable is automatically populated if running ZSEC script
##    and thus will override any value set here. Only uncomment and set this value if you are deploying terraform standalone.

#region                                     = "us-central1"

## 6. Path relative to terraform root directory where the service account json file exists for terraform to authenticate to Google Cloud

#credentials                                = "/tmp/ac-tf-service-account.json"

## 7. GCP Project ID to deploy/reference resources created

#project                                    = "ac-host-project"


#####################################################################################################################
##### Custom variables. Only change if required for your environment  #####
#####################################################################################################################
## 8. The name string for all App Connector resources created by Terraform for Tag/Name attributes. (Default: zsac)
##    Due to GCP character constraints, there are validations where this value must be 12 or less characters and only
##    lower case.

#name_prefix                                = "zsac"

## 9. App Connector GCP Compute Instance size selection. Uncomment acvm_instance_type line with desired vm size to change.
##    (Default: n2-standard-2)

#acvm_instance_type                         = "n2-standard-2"
#acvm_instance_type                         = "e2-standard-2"
#acvm_instance_type                         = "n2-standard-4"
#acvm_instance_type                         = "e2-standard-4"
#acvm_instance_type                         = "n2-standard-8"
#acvm_instance_type                         = "e2-standard-8"

## 10. Network Configuration:
##    Subnet space. (Minimum /28 required. Uncomment and modify if byo_vpc is set to true but byo_subnets is left false meaning you want terraform to create 
##    NEW subnets in those existing VPCs.

## Note: These Greenfield templates that include a test workload and bastion host will create a total of two VPC Networks in the same Project ID. Putting
##       Host/Services and Applications in the same Project is generally not a GCP recommended best practice. For simplicity, we will create a "Management"
##       VPC consisting of the public bastion VM (subnet_bastion) and the App Connector Mgmt NIC (subnet_ac).

#subnet_bastion                             = "10.0.0.0/24"
#subnet_ac                                  = "10.0.1.0/24"

## 11. Availabilty Zone resiliency configuration:

## Option A. By default, Terraform will perform a lookup on the region being deployed for what/how many availability zones are currently available for use.
##           Based on this output, we will take the first X number of available zones per az_count and create Compute Instance Groups in in each. Available 
##           input range 1-3 (Default: 1) 

## Example: Region is us-central1 with az_count set to 2. Terraform will create 1 Instance Group in us-central1-a and 1x Instance Group in us-central1-b
##          (or whatever first two zones report back as available)

#az_count                                   = 1


## Option B. If you require Instance Groups to be set explicitly in certain availability zones, you can override the region lookup and set the zones.

## Note: By setting zone names here, Terraform will ignore any value set for variable az_count. We also cannot verify the availability correct naming syntax
##       of the names set.

#zones                                      = ["us-central1-a","us-central1-b"]

## 12. The number of App Connector appliances to provision per Instance Group/Availability Zone.
##    (Default: varies per deployment type template)
##    E.g. ac_count set to 2 and var.az_count or var.zones set to 2 will create 2x Zonal Instance Groups with 2x target CCs in each Instance Group

#ac_count                                   = 1

## 13. Custom image name to used for deploying App Connector appliances. By default, Terraform will lookup the latest CentOS 7 image version from the Google Marketplace.
##     This variable is provided if a customer desires to override/retain a specific image name/Instance Template version

## Note: It is NOT RECOMMENDED to statically set AC image versions. Zscaler recommends always running/deploying the latest version template

#image_id                                   = "centos-7-v20230711"


#####################################################################################################################
##### Custom BYO variables. Only applicable for deployments without "base" resource requirements  #####
#####                                 E.g. "ac"                                                   #####
#####################################################################################################################
## 14. By default, this script will create a new GCP VPC Network for App Connector.
##     Uncomment if you want to deploy all resources to a VPC that already exists (true or false. Default: false)

#byo_vpc                                    = true

## 15. Provide your existing VPC Network friendly name. Only uncomment and modify if you set byo_vpc to true. (Default: null)

##byo_vpc_name                              = "ac-vpc-123"

## 16. By default, this script will create a new subnet in the specified VPC Network.
##     Uncomment if you want to deploy all resources to a subnet that already exist (true or false. Default: false)
##     Dependencies require in order to reference existing subnets, the corresponding VPC must also already exist.
##     Setting byo_subnet to true means byo_vpc must ALSO be set to true.

#byo_subnets                                = true

## 17. Provide your existing App Connector subnet friendly names. Only uncomment and modify if you set byo_subnets to true.

#byo_subnet_name                            = "ac-vpc-subnet"

## 18. By default, this script will create new Cloud Routers in the specified VPC Network.
##     Uncomment if you want to deploy to a VPC where Cloud Router already exists. (true or false. Default: false)
##     Dependencies require in order to reference existing Cloud Routers, the corresponding VPC must also already exist.
##     Setting byo_router to true means byo_vpc must ALSO be set to true.

#byo_router                                 = true

## 19. Provider your existing Cloud Router friendly names. Only uncomment and modify if you set byo_router to true.

#byo_router_name                            = "ac-vpc-router"

## 20. By default, this script will create new Cloud NAT Gateways associated with VPC Cloud Router in
##     the specified VPC Network. Uncomment if you want to deploy to a VPC where NAT Gateway already exists. 
##     (true or false. Default: false).
##     Dependencies require in order to reference existing Cloud NAT Gateway, the corresponding VPC Networks
##     AND Cloud Routers must also already exist.
##     Setting byo_natgw to true means byo_vpc AND byo_router must ALSO be set to true.

#byo_natgw                                  = true

## 21. Provide your existing Cloud NAT Gateway friendly names. Only uncomment and modify if you set byo_natgw to true.

#byo_natgw_name                             = "ac-vpc-natgw"
