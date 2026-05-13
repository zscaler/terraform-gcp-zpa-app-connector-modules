## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment

## Variables are populated automatically if terraform is ran via the zsac bash script.
## Modifying the variables in this file will override any inputs from zsac.


#####################################################################################################################
##### Optional: ZPA Provider Resources. Skip to step 3. if you already have an  #####
##### App Connector Group + Provisioning Key.                                   #####
#####################################################################################################################

## 1. ZPA App Connector Provisioning Key variables. Uncomment and replace default values as desired for your deployment.
##    For any questions populating the below values, please reference:
##    https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_provisioning_key

#provisioning_key_name                          = "new_key_name"
#provisioning_key_enabled                       = true
#provisioning_key_max_usage                     = 100
# Note: the "Connector" enrollment certificate is now resolved automatically
# inside the modules. There is no longer an `enrollment_cert` input.
#
# Note: for ASG deployments, set provisioning_key_max_usage comfortably above
# var.max_size * length(var.zones) to leave room for instance churn over the
# life of the autoscaling group.

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
#app_connector_group_dns_query_type             = "IPV4_IPV6"
# Note: the version profile is pinned to "Default" inside the module via
# `data "zpa_customer_version_profile"`. There is no longer an
# `app_connector_group_version_profile_id` input.


#####################################################################################################################
##### Optional: bring-your-own provisioning key. Skip if you populated step 1.                                  #####
#####################################################################################################################

## 3. By default this example creates a new App Connector Group + Provisioning Key.
##    Uncomment if you want to reuse an existing provisioning key.

#byo_provisioning_key                           = true
#byo_provisioning_key_name                      = "example-key-name"


#####################################################################################################################
##### Terraform / Cloud Environment variables                                                                   #####
#####################################################################################################################

## 4. GCP region where App Connector resources will be deployed.
# region = "us-central1"

## 5. Path to a service account JSON file (optional). Leave commented to fall
##    back to Application Default Credentials (recommended).
#credentials                                = "/tmp/ac-tf-service-account.json"

## 6. GCP Project ID
# project = "my-gcp-project"


#####################################################################################################################
##### Custom variables. Only change if required for your environment                                            #####
#####################################################################################################################

## 7. Name prefix for tags / resource naming. Must be 12 chars or less.
# name_prefix = "zsac"

## 8. App Connector instance type. (Default: n2-standard-4)
#acvm_instance_type                         = "n2-standard-4"

## 9. Network configuration (greenfield).
#subnet_bastion                             = "10.0.0.0/24"
#subnet_ac                                  = "10.0.1.0/24"

## 10. Multi-AZ resilience.
##     az_count = how many zones to spread MIGs across (1-3, default 1).
##     One MIG + one Autoscaler is created per zone.
# az_count = 1

#zones                                      = ["us-central1-a"]


#####################################################################################################################
##### Autoscaling controls                                                                                       #####
#####################################################################################################################

## 11. Per-zone min / max instance counts. With az_count = 2 and max_size = 4,
# ##     the cluster can scale up to 8 instances total (4 per zone).
# min_size = 2
# max_size = 4

## 12. Scaling metric. Names mirror the AWS ASG predefined metric types so
##     callers can switch clouds without renaming.
##     Approved values:
##       - ASGAverageCPUUtilization (recommended)
##       - ASGAverageNetworkIn
##       - ASGAverageNetworkOut
# target_tracking_metric = "ASGAverageCPUUtilization"

## 13. Target value for the chosen metric.
##     For CPU: percentage 1-100 (50 = scale to keep avg CPU at ~50%)
##     For Network: bytes-per-second per instance
# target_cpu_util_value = 50

## 14. Cooldown period (seconds) the autoscaler waits before sampling a fresh
##     instance after launch. Default 60s is conservative for fast-booting AMIs.
#cooldown_period                            = 60

## 15. Health-check grace period (seconds). The autohealing health check waits
##     this long before checking a newly-launched VM. App Connector first-boot
##     can take several minutes (yum install, service start, ZPA enrollment).
#health_check_grace_period                  = 300


#####################################################################################################################
##### Image selection                                                                                            #####
#####################################################################################################################

## 16. Use the Zscaler-published GCP Marketplace image, or fall back to RHEL 9.
# use_zscaler_image                          = true
