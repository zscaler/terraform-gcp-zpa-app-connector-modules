![GitHub release (latest by date)](https://img.shields.io/github/v/release/zscaler/terraform-gcp-zpa-app-connector-modules?style=flat-square)
![GitHub](https://img.shields.io/github/license/zscaler/terraform-gcp-zpa-app-connector-modules?style=flat-square)
![GitHub pull requests](https://img.shields.io/github/issues-pr/zscaler/terraform-gcp-zpa-app-connector-modules?style=flat-square)
![Terraform registry downloads total](https://img.shields.io/badge/dynamic/json?color=green&label=downloads%20total&query=data.attributes.total&url=https%3A%2F%2Fregistry.terraform.io%2Fv2%2Fmodules%2Fzscaler%2Fzpa-app-connector-modules%2Fgcp%2Fdownloads%2Fsummary&style=flat-square)
![Terraform registry download month](https://img.shields.io/badge/dynamic/json?color=green&label=downloads%20this%20month&query=data.attributes.month&url=https%3A%2F%2Fregistry.terraform.io%2Fv2%2Fmodules%2Fzscaler%2Fzpa-app-connector-modules%2Fgcp%2Fdownloads%2Fsummary&style=flat-square)
[![Automation Hub](https://img.shields.io/badge/automation-hub-blue)](https://automate.zscaler.com/docs/tools/sdk-documentation/sdk-getting-started)
[![Zscaler Community](https://img.shields.io/badge/zscaler-community-blue)](https://community.zscaler.com/)

# Zscaler App Connector GCP Terraform Modules

## Support Disclaimer

-> **Disclaimer:** Please refer to our [General Support Statement](docs/guides/support.md) before proceeding with the use of this provider.

## Description
This repository contains various modules and deployment configurations that can be used to deploy Zscaler App Connector appliances to securely connect to workloads within Google Cloud (GCP) via the Zscaler Zero Trust Exchange. The [examples](examples/) directory contains complete automation scripts for both greenfield/POV and brownfield/production use.

These deployment templates are intended to be fully functional and self service for both greenfield/pov as well as production use. All modules may also be utilized as design recommendation based on Zscaler's Official [Zero Trust Access to Private Apps in GCP with ZPA](https://www.zscaler.com/resources/reference-architecture/zero-trust-with-zpa.pdf).

~> **IMPORTANT** As of version 1.1.0 of this module, all App Connectors are deployed using the new [Red Hat Enterprise Linux 9](https://help.zscaler.com/zpa/app-connector-red-hat-enterprise-linux-9-migration)

## **Prerequisites**

The GCP Terraform scripts leverage Terraform v1.1.9 which includes full binary and provider support for macOS M1 chips, but any Terraform
version 0.13.7 should be generally supported.

-   provider registry.terraform.io/hashicorp/google v7.31.x
-   provider registry.terraform.io/hashicorp/random v3.8.x
-   provider registry.terraform.io/hashicorp/local v2.8.x
-   provider registry.terraform.io/hashicorp/null v3.2.x
-   provider registry.terraform.io/hashicorp/tls v4.2.x
-   provider registry.terraform.io/zscaler/zpa v4.4.x

### **GCP requirements**

1.  A valid GCP account with Administrator Access to deploy required resources
2.  GCP service account keyfile
3.  GCP Region (E.g. us-central1)

### Zscaler requirements

1. A valid Zscaler Private Access subscription and portal access.
2. API credentials for the ZPA Terraform Provider. See the [Zscaler OneAPI](#zscaler-oneapi) section below to choose between OneAPI (recommended) and legacy ZPA authentication, and follow the linked provider documentation to generate the appropriate credentials.
3. (Optional) An existing App Connector Group and Provisioning Key. Otherwise the examples will create them for you based on values in `terraform.tfvars`.

See: [Zscaler App Connector Deployment for Linux](https://help.zscaler.com/zpa/app-connector-deployment-guide-linux) for additional prerequisite provisioning steps.

## Zscaler OneAPI

This module leverages the official [ZPA Terraform Provider](https://registry.terraform.io/providers/zscaler/zpa/latest/docs), which authenticates against Zscaler [OneAPI](https://help.zscaler.com/oneapi/understanding-oneapi) using OAuth2 through [Zidentity](https://help.zscaler.com/zidentity/what-zidentity). OneAPI is the recommended authentication method for all new deployments.

The provider also retains backwards compatibility with the legacy ZPA API framework for organizations whose tenants have not yet been migrated to Zidentity. Both methods are fully supported, but we recommend moving to OneAPI when feasible.

**NOTE:** OneAPI and Zidentity are not supported in the `GOV` and `GOVUS` clouds. Tenants in those environments must use the legacy ZPA authentication method.

Refer to the [ZPA Terraform Provider documentation](https://registry.terraform.io/providers/zscaler/zpa/latest/docs#authentication) for the full list of supported authentication variables for both methods.

### Terraform client requirements

If executing Terraform via the `zsac` wrapper bash script, run it from a macOS or Linux workstation. The script requires:
- bash
- curl
- unzip

## How to deploy
Provisioning templates are available for customer use/reference to successfully deploy fully operational App Connector appliances once the prerequisites have been completed. Please follow the instructions located in [examples](examples/README.md).

## Structure

This repository has the following directory structure:

* [modules](./modules): This directory contains several standalone, reusable, production-grade Terraform modules. Each module is individually documented.
* [examples](./examples): This directory shows examples of different ways to combine the modules contained in the
  `modules` directory.

## Compatibility

The compatibility with Terraform is defined individually per each module. In general, expect the earliest compatible
Terraform version to be 1.0.0 across most of the modules.
<!-- [FUTURE] If you need to stay on Terraform 0.15.3 and need to use these modules, the recommended last compatible release is 1.2.3. -->

## Format

This repository follows the [Hashicorp Standard Modules Structure](https://www.terraform.io/registry/modules/publish):

* `modules` - All module resources utilized by and customized specifically for App Connector deployments. The intent is these modules are resusable and functional for any deployment type referencing for both production or lab/testing purposes.
* `examples` - Zscaler provides fully functional deployment templates utilizing a combination of some or all of the modules published. These can utilized in there entirety or as reference templates for more advanced customers or custom deployments. For novice Terraform users, we also provide a bash script (zsac) that can be run from any Linux/Mac OS or CSP Cloud Shell that walks through all provisioning requirements as well as downloading/running an isolated teraform process. This allows App Connector deployments from any supported client without needing to even have Terraform installed or know how the language/syntax for running it.

## Versioning

These modules follow recommended release tagging in [Semantic Versioning](http://semver.org/). You can find each new release,
along with the changelog, on the GitHub [Releases](https://github.com/zscaler/terraform-gcp-zpa-app-connector-modules/releases) page.

## Contributing

Contributions are welcome, and they are greatly appreciated! Every little bit helps,
and credit will always be given. Please follow our [contributing guide](docs/guides/contributing.md)

# License and Copyright

Copyright (c) 2022 Zscaler, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
