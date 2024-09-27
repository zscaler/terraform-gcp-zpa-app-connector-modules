terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.0"
    }
  }

  required_version = ">= 0.13.7, < 2.0.0"
}
