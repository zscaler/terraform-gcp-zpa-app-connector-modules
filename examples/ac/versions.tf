terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.70.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.4.0"
    }
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 2.8.0"
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
