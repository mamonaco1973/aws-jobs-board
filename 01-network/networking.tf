# ==============================================================================
# Network Baseline
# ==============================================================================
# VPC (/23) with DNS support, two private subnets across AZs for RDS/ECS,
# two public subnets for ALB/NAT Gateway placement.
# ==============================================================================

resource "aws_vpc" "ecs-vpc" {
  cidr_block           = "10.0.0.0/23"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "ecs-vpc" }
}

resource "aws_internet_gateway" "ecs-igw" {
  vpc_id = aws_vpc.ecs-vpc.id
  tags   = { Name = "ecs-igw" }
}

# ------------------------------------------------------------------------------
# Subnets
# priv-subnet-1/2: ECS tasks + RDS + Redis (no public IP)
# pub-subnet-1/2:  ALB + NAT Gateway placement
# ------------------------------------------------------------------------------
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

resource "aws_eip" "nat_eip" {
  tags = { Name = "nat-eip" }
}

# NAT Gateway in public subnet — private subnet egress for ECS pulls, DB updates
resource "aws_nat_gateway" "ecs_nat" {
  subnet_id     = aws_subnet.pub-subnet-1.id
  allocation_id = aws_eip.nat_eip.id
  tags          = { Name = "ecs-nat" }
}

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

resource "aws_route_table_association" "priv1" {
  subnet_id      = aws_subnet.priv-subnet-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv2" {
  subnet_id      = aws_subnet.priv-subnet-2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.pub-subnet-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.pub-subnet-2.id
  route_table_id = aws_route_table.public.id
}
