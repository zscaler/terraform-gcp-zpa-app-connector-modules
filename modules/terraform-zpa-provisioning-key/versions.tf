terraform {
  required_providers {
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 3.33.0"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}
