provider "aws" {
  region  = "ap-southeast-1"
  profile = "default"
}

terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
