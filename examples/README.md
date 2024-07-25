# Zscaler App Connector Cluster Infrastructure Setup

**Terraform configurations and modules for deploying Zscaler App Connector Cluster in GCP.**

## Prerequisites (You will be prompted for GCP keys and region during deployment)

### **GCP requirements**

1.  A valid GCP account with Administrator Access to deploy required resources
2.  GCP service account keyfile
3.  GCP Region (E.g. us-central1)

### Zscaler requirements
This module leverages the Zscaler Private Access [ZPA Terraform Provider](https://registry.terraform.io/providers/zscaler/zpa/latest/docs) for the automated onboarding process. Before proceeding make sure you have the following pre-requistes ready.

1. A valid Zscaler Private Access subscription and portal access
2. Zscaler ZPA API Keys. Details on how to find and generate ZPA API keys can be located [here](https://help.zscaler.com/zpa/about-api-keys#:~:text=An%20API%20key%20is%20required,from%20the%20API%20Keys%20page)
- Client ID
- Client Secret
- Customer ID
3. (Optional) An existing App Connector Group and Provisioning Key. Otherwise, you can follow the prompts in the examples terraform.tfvars to create a new Connector Group and Provisioning Key

See: [Zscaler App Connector Deployment for Linux](https://help.zscaler.com/zpa/app-connector-deployment-guide-linux) for additional prerequisite provisioning steps.

### **Terraform client requirements**
7. If executing Terraform via the "zsec" wrapper bash script, it is advised that you run from a MacOS or Linux workstation. Minimum installed application requirements to successfully from the script are:
- bash
- curl
- unzip
<br>
<br>

## Deploying the cluster
(The automated tool can run only from MacOS and Linux. You can also upload all repo contents to the respective public cloud provider Cloud Shells and run directly from there).   
 
**1. Greenfield Deployments**

(Use this if you are building an entire cluster from ground up.
 Particularly useful for a Customer Demo/PoC or dev-test environment)

```
bash
cd examples
Optional: Edit the terraform.tfvars file under your desired deployment type (ie: base_ac) to setup your App Connector (Details are documented inside the file)
- ./zsec up
- enter "greenfield"
- enter <desired deployment type>
- follow prompts for any additional configuration inputs. *keep in mind, any modifications done to terraform.tfvars first will override any inputs from the zsec script*
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm
```

**Greenfield Deployment Types:**

```
Deployment Type: (base_ac):
base_ac: Creates 1 new "Management" VPC with 1 AC-Mgmt subnet and 1 bastion subnet; 1 Cloud Router + NAT Gateway; 1 Bastion Host assigned a dynamic public IP; generates local key pair .pem file for ssh access to all VMs; 1 App Connector compute instance template + option to deploy multiple App Connectors across multiple zonal managed instance groups for highly available/resilient workload Zero Trust App Access.
```

**2. Brownfield Deployments**

(These templates would be most applicable for production deployments and have more customization options than a "base" deployments). They also do not include a bastion or workload hosts deployed.

```
bash
cd examples
Optional: Edit the terraform.tfvars file under your desired deployment type (ie: ac) to setup your App Connector (Details are documented inside the file)
- ./zsec up
- enter "brownfield"
- enter <desired deployment type>
- follow prompts for any additional configuration inputs. *keep in mind, any modifications done to terraform.tfvars first will override any inputs from the zsec script*
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm
```

**Brownfield Deployment Types**

```
Deployment Type: (ac):
ac: Creates 1 new "Management" VPC with 1 AC-Mgmt subnet; 1 Cloud Router + NAT Gateway; generates local key pair .pem file for ssh access to all VMs. All network infrastructure resource have conditional "byo" variables, that can be inputted if they already exist (like VPC, subnet, Cloud Router, and Cloud NAT); creates 1 App Connector compute instance template + option to deploy multiple App Connectors across multiple zonal managed instance groups for highly available/resilient workload Zero Trust App Access.
```

## Destroying the cluster
```
cd examples
- ./zsec destroy
- verify all resources that will be destroyed and enter "yes" to confirm
```

## Notes
```
1. For auto approval set environment variable **AUTO_APPROVE** or add `export AUTO_APPROVE=1`
2. For deployment type set environment variable **dtype** to the required deployment type or add `export dtype=base_ac`
3. To provide new credentials or region, delete the autogenerated .zsecrc file in your current working directory and re-run zsec.
```
