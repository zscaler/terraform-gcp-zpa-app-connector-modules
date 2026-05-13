## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment

## Variables are populated automatically if terraform is ran via the zsac bash script.

#####################################################################################################################
##### ZPA Provider Resources                                                                                     #####
#####################################################################################################################

## 1. ZPA App Connector Provisioning Key
#provisioning_key_name                          = "new_key_name"
#provisioning_key_enabled                       = true
#provisioning_key_max_usage                     = 100
# Note: for ASG deployments, set provisioning_key_max_usage comfortably above
# var.max_size * length(var.zones) to leave room for instance churn.

## 2. ZPA App Connector Group
#app_connector_group_name                       = "new_group_name"
#app_connector_group_description                = "group_description"
#app_connector_group_country_code               = "US"
#app_connector_group_location                   = "San Jose, CA, USA"
#app_connector_group_dns_query_type             = "IPV4_IPV6"

## 3. BYO provisioning key (optional)
#byo_provisioning_key                           = true
#byo_provisioning_key_name                      = "example-key-name"


#####################################################################################################################
##### Terraform / Cloud Environment variables                                                                   #####
#####################################################################################################################

## 4. GCP region
#region = "us-central1"

## 5. Path to a service account JSON file (optional). Leave commented to use ADC.
#credentials                                = "/tmp/ac-tf-service-account.json"

## 6. GCP Project ID
#project = "project_id"


#####################################################################################################################
##### Custom variables. Only change if required for your environment                                            #####
#####################################################################################################################

## 7. Resource name prefix.
#name_prefix = "zsac"

## 8. App Connector instance type. (Default: n2-standard-4)
#acvm_instance_type                         = "n2-standard-4"

## 9. AZ resilience.
#az_count = 1
#zones                                      = ["us-central1-a"]


#####################################################################################################################
##### Brownfield: bring-your-own VPC / subnets / router / NAT                                                    #####
#####################################################################################################################

## 10. Use an existing VPC. Set byo_vpc to true and provide the VPC name.
#byo_vpc                                    = true
#byo_vpc_name                               = "my-existing-vpc"

## 11. Use existing subnets in that VPC. If left false, Terraform creates new subnets.
#byo_subnets                                = true
#byo_subnet_name                            = "my-existing-ac-subnet"
#subnet_ac                                  = "10.0.1.0/24"   # only used if byo_subnets=false

## 12. Use existing Cloud Router.
#byo_router                                 = true
#byo_router_name                            = "my-existing-router"

## 13. Use existing NAT Gateway.
#byo_natgw                                  = true
#byo_natgw_name                             = "my-existing-natgw"


#####################################################################################################################
##### Autoscaling controls                                                                                       #####
#####################################################################################################################

## 14. Per-zone min / max instance counts.
# min_size = 2
# max_size = 4

## 15. Scaling metric. Names mirror the AWS ASG predefined metric types.
##     Approved values:
##       - ASGAverageCPUUtilization (recommended)
##       - ASGAverageNetworkIn
##       - ASGAverageNetworkOut
# target_tracking_metric = "ASGAverageCPUUtilization"

## 16. Target value for the chosen metric.
##     CPU: percentage 1-100 (50 = scale to keep avg CPU at ~50%)
##     Network: bytes-per-second per instance
# target_cpu_util_value = 50

## 17. Optional autoscaler/healing tuning.
# cooldown_period                            = 60
# health_check_grace_period                  = 300


#####################################################################################################################
##### Image selection                                                                                            #####
#####################################################################################################################

## 18. Use the Zscaler-published GCP Marketplace image, or fall back to RHEL 9.
# use_zscaler_image                          = true
