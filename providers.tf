# Terraform provider version
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.27"
    }
  }
}

# Defining AWS provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  # shared_config_files = [ "/Users/whoami/.aws/config" ]
  # shared_credentials_files = [ "/Users/whoami/.aws/credentials" ]
}