terraform {
  required_version = "~> 1.5.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.16.1"
    }
  }
  backend "s3" {
    region = "ca-central-1"
    bucket = "nixfra-staging-tfstate"
    key    = "main"
  }
}

variable "region" {
  type = string
}

provider "aws" {
  region = var.region
}
