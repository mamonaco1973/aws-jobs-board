# ==============================================================================
# DATA BLOCK: AWS VPC
# ------------------------------------------------------------------------------
# Retrieves details of an existing AWS VPC using tag filters. The VPC must
# already exist in the target AWS account and region. This avoids hardcoding
# VPC IDs and allows dynamic referencing by tag.
# ==============================================================================
data "aws_vpc" "ecs-vpc" {
  # FILTER: Select VPC by tag
  filter {
    name   = "tag:Name"  # Filter by the "Name" tag
    values = ["ecs-vpc"] # Match the VPC name tag value
  }
}

# ==============================================================================
# DATA BLOCK: AWS SUBNET 1
# ------------------------------------------------------------------------------
# Retrieves details for the first public subnet by its "Name" tag. Typically
# used for associating resources like EC2 instances or load balancers with
# specific subnets.
# ==============================================================================
data "aws_subnet" "ecs-subnet-1" {
  # FILTER: Select subnet by tag
  filter {
    name   = "tag:Name"       # Filter by the "Name" tag
    values = ["pub-subnet-1"] # Match the subnet tag value
  }
}

# ==============================================================================
# DATA BLOCK: AWS SUBNET 2
# ------------------------------------------------------------------------------
# Retrieves details for the second public subnet using its "Name" tag. Useful
# for multi-AZ or high-availability deployments requiring multiple subnets.
# ==============================================================================
data "aws_subnet" "ecs-subnet-2" {
  # FILTER: Select subnet by tag
  filter {
    name   = "tag:Name"       # Filter by the "Name" tag
    values = ["pub-subnet-2"] # Match the subnet tag value
  }
}

# ==============================================================================
# DATA BLOCK: AWS PRIVATE SUBNET 1
# ------------------------------------------------------------------------------
# Retrieves information about the first private subnet using its "Name" tag.
# Enables referencing private subnets dynamically without hardcoding IDs.
# ==============================================================================
data "aws_subnet" "ecs-private-subnet-1" {
  # FILTER: Select subnet by tag
  filter {
    name   = "tag:Name"        # Filter by the "Name" tag
    values = ["priv-subnet-1"] # Match the private subnet tag
  }
}

# ==============================================================================
# DATA BLOCK: AWS PRIVATE SUBNET 2
# ------------------------------------------------------------------------------
# Retrieves information about the second private subnet using its "Name" tag.
# Supports multi-AZ or HA deployments spanning private subnets.
# ==============================================================================
data "aws_subnet" "ecs-private-subnet-2" {
  # FILTER: Select subnet by tag
  filter {
    name   = "tag:Name"        # Filter by the "Name" tag
    values = ["priv-subnet-2"] # Match the private subnet tag
  }
}

# ------------------------------------------------------------------------------ 
# DATA SOURCE: Existing EFS File System (lookup by tag)
# ------------------------------------------------------------------------------
data "aws_efs_file_system" "efs" {
  tags = {
    Name = "mcloud-efs"
  }
}

# ==============================================================================
# Lookup the latest Amazon ECS-Optimized AMI for Amazon Linux 2
# ------------------------------------------------------------------------------
# This uses AWS Systems Manager (SSM) Parameter Store to dynamically fetch
# the latest ECS-optimized AMI ID for your region.
# ==============================================================================

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}
