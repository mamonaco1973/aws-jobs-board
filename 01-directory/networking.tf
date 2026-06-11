# ==========================================================================================
# Network Baseline for mini-AD
# ------------------------------------------------------------------------------------------
# Purpose:
#   - Defines networking components for Active Directory lab environment
#   - Components:
#       * VPC (/23) with DNS support/hostnames enabled
#       * Private utility subnets (VMs/bastion/utility hosts)
#       * Public subnets for NAT Gateway placement
#       * Private subnet for AD Domain Controllers
#       * Internet Gateway for public subnets
#       * NAT Gateway for private subnet egress
#       * Route tables (public + private) and associations
#
# Notes:
#   - CIDR ranges and AZs are example values; adjust to match region/IP plan
#   - Utility “vm” subnets are private (egress via NAT only, no inbound exposure)
# ==========================================================================================


# ------------------------------------------------------------------------------------------
# VPC
# - Lab VPC with DNS support and hostnames enabled
# ------------------------------------------------------------------------------------------
resource "aws_vpc" "ecs-vpc" {
  cidr_block           = "10.0.0.0/23"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "ecs-vpc" }
}


# ------------------------------------------------------------------------------------------
# Internet Gateway
# - Provides internet egress for NAT/public subnets
# ------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "ecs-igw" {
  vpc_id = aws_vpc.ecs-vpc.id
  tags   = { Name = "ecs-igw" }
}


# ------------------------------------------------------------------------------------------
# Subnets
# - vm-subnet-1: utility/private VMs (AZ6), outbound via NAT only
# - vm-subnet-2: utility/private VMs (AZ4), outbound via NAT only
# - pub-subnet-1: NAT placement (public, AZ4)
# - pub-subnet-2: NAT placement (public, AZ6)
# - ad-subnet: domain controllers (private, AZ4)
# ------------------------------------------------------------------------------------------
resource "aws_subnet" "priv-subnet-1" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = "10.0.0.64/26"
  map_public_ip_on_launch = false
  availability_zone_id    = "use1-az6"

  tags = { Name = "priv-subnet-1" }
}

resource "aws_subnet" "priv-subnet-2" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = "10.0.0.128/26"
  map_public_ip_on_launch = false
  availability_zone_id    = "use1-az4"

  tags = { Name = "priv-subnet-2" }
}

resource "aws_subnet" "pub-subnet-1" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = "10.0.0.192/26"
  map_public_ip_on_launch = true
  availability_zone_id    = "use1-az4"

  tags = { Name = "pub-subnet-1" }
}

resource "aws_subnet" "pub-subnet-2" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = "10.0.1.0/26"
  map_public_ip_on_launch = true
  availability_zone_id    = "use1-az6"

  tags = { Name = "pub-subnet-2" }
}

resource "aws_subnet" "ad-subnet" {
  vpc_id                  = aws_vpc.ecs-vpc.id
  cidr_block              = "10.0.0.0/26"
  map_public_ip_on_launch = false
  availability_zone_id    = "use1-az4"

  tags = { Name = "ad-subnet" }
}


# ------------------------------------------------------------------------------------------
# Elastic IP for NAT
# - Provides static public IP for NAT Gateway egress
# ------------------------------------------------------------------------------------------
resource "aws_eip" "nat_eip" {
  tags = { Name = "nat-eip" }
}


# ------------------------------------------------------------------------------------------
# NAT Gateway
# - Placed in public subnet; provides outbound internet to private subnets
# ------------------------------------------------------------------------------------------
resource "aws_nat_gateway" "ecs_nat" {
  subnet_id     = aws_subnet.pub-subnet-1.id
  allocation_id = aws_eip.nat_eip.id
  tags          = { Name = "ecs-nat" }
}


# ------------------------------------------------------------------------------------------
# Route Tables
# - Public: default route to IGW
# - Private: default route to NAT
# ------------------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecs-vpc.id
  tags   = { Name = "public-route-table" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ecs-igw.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ecs-vpc.id
  tags   = { Name = "private-route-table" }
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ecs_nat.id
}


# ------------------------------------------------------------------------------------------
# Route Table Associations
# - vm-subnets + ad-subnet → private route table (egress via NAT)
# - pub-subnets → public route table (egress via IGW)
# ------------------------------------------------------------------------------------------
resource "aws_route_table_association" "rt_assoc_priv_subnet_1" {
  subnet_id      = aws_subnet.priv-subnet-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "rt_assoc_priv_subnet_2" {
  subnet_id      = aws_subnet.priv-subnet-2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "rt_assoc_ad_private" {
  subnet_id      = aws_subnet.ad-subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "rt_assoc_pub_public" {
  subnet_id      = aws_subnet.pub-subnet-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "rt_assoc_pub_public_2" {
  subnet_id      = aws_subnet.pub-subnet-2.id
  route_table_id = aws_route_table.public.id
}
