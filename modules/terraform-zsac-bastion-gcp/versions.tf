terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.31.0"
    }
  }

  required_version = ">= 0.13.7, < 2.0.0"
}
