terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.4.0"
    }
  }

  required_version = ">= 0.13.7, < 2.0.0"
}
