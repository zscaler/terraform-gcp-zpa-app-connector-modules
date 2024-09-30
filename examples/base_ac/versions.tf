terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 3.33.0"
    }
  }

  required_version = ">= 0.13.7, < 2.0.0"
}

# Configure the Google Provider
provider "google" {
  credentials = var.credentials
  project     = var.project
  region      = var.region
}

# Configure the ZPA Provider
provider "zpa" {
}
