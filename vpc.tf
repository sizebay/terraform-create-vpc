locals {
  name_prefix = "${var.project}-${var.environment}"
}

# -------------------------------------------------------
# VPC
# -------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.name_prefix}-vpc"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# -------------------------------------------------------
# Internet Gateway
# -------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.name_prefix}-igw"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# -------------------------------------------------------
# Public Subnets (ALB + NAT Gateway) — uma por AZ
# -------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-public-${var.availability_zones[count.index]}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Tier        = "public"
  }
}

# -------------------------------------------------------
# Private Subnets (EC2 instances) — uma por AZ
# -------------------------------------------------------
resource "aws_subnet" "private" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-private-${var.availability_zones[count.index]}"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Tier        = "private"
  }
}

# -------------------------------------------------------
# Elastic IP para o NAT Gateway
# -------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-nat-eip"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# -------------------------------------------------------
# NAT Gateway (na primeira subnet pública)
# -------------------------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${local.name_prefix}-nat-gw"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }

  depends_on = [aws_internet_gateway.main]
}

# -------------------------------------------------------
# Route Table — Pública (tráfego via IGW)
# -------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${local.name_prefix}-rt-public"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------------------------------------
# Route Table — Privada (tráfego via NAT Gateway)
# -------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${local.name_prefix}-rt-private"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
