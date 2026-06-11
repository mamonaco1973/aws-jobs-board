# ==========================================================================================
# AWS Provider + Data Sources (Windows AMI + AD Infrastructure)
# ------------------------------------------------------------------------------------------
# Purpose:
#   - Configures AWS provider in us-east-1 (N. Virginia)
#   - Fetches existing infrastructure components for Active Directory integration:
#       * Secrets Manager secret (AD admin credentials)
#       * Subnets (VM, public, AD placement)
#       * VPC (Active Directory environment)
#       * Latest Windows Server 2022 AMI (from Amazon)
# ==========================================================================================


# ------------------------------------------------------------------------------------------
# AWS Provider
# - Defines AWS provider region (override for multi-region deployments)
# ------------------------------------------------------------------------------------------
provider "aws" {
  region = "us-east-1" # Default region: N. Virginia
}


# ------------------------------------------------------------------------------------------
# Secrets Manager: AD Admin Credentials
# - Retrieves stored secret for AD administrator credentials
# ------------------------------------------------------------------------------------------
data "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials"
}


# ------------------------------------------------------------------------------------------
# Subnet Lookups
# - Retrieves subnets by tag for VM placement, public ALB, and AD servers
# ------------------------------------------------------------------------------------------
data "aws_subnet" "priv_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["priv-subnet-1"]
  }
}

data "aws_subnet" "priv_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["priv-subnet-2"]
  }
}

data "aws_subnet" "pub_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["pub-subnet-1"]
  }
}

data "aws_subnet" "pub_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["pub-subnet-2"]
  }
}

data "aws_subnet" "ad_subnet" {
  filter {
    name   = "tag:Name"
    values = ["ad-subnet"]
  }
}


# ------------------------------------------------------------------------------------------
# VPC Lookup
# - Retrieves AD-specific VPC by Name tag
# ------------------------------------------------------------------------------------------
data "aws_vpc" "ecs_vpc" {
  filter {
    name   = "tag:Name"
    values = ["ecs-vpc"]
  }
}


# ------------------------------------------------------------------------------------------
# AMI Lookup: Windows Server 2022
# - Selects the most recent Windows Server 2022 AMI published by Amazon
# ------------------------------------------------------------------------------------------
data "aws_ami" "windows_ami" {
  most_recent = true
  owners      = ["amazon"] # AWS official AMIs

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}
