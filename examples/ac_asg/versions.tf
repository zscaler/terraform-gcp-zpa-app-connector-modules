terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.31.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.8.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2.0"
    }
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 4.4.0"
    }
  }

  required_version = ">= 0.13.7, < 2.0.0"
}

provider "google" {
  credentials = var.credentials
  project     = var.project
  region      = var.region
}

# Note on credentials precedence:
# - If `var.credentials` is set, it is used (path to a JSON key file or the JSON itself).
# - If left null/empty, the google provider falls back to:
#     1. GOOGLE_CREDENTIALS / GOOGLE_APPLICATION_CREDENTIALS env vars
#     2. Application Default Credentials (`gcloud auth application-default login`)

provider "zpa" {
}
