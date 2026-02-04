########################
# AZs
########################
data "aws_availability_zones" "available" {
  state = "available"
}

########################
# VPC
########################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    { Name = "lab-vpc" }
  )
}

########################
# INTERNET GATEWAY
########################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    { Name = "lab-igw" }
  )
}

########################
# PUBLIC SUBNETS (2)
########################
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "lab-public-${count.index + 1}"
      Tier = "public"
    }
  )
}

########################
# PRIVATE SUBNETS (2)
########################
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    var.tags,
    {
      Name = "lab-private-${count.index + 1}"
      Tier = "private"
    }
  )
}

########################
# PUBLIC ROUTE TABLE
########################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    { Name = "lab-public-rt" }
  )
}

########################
# PUBLIC ROUTE TABLE ASSOCIATION
########################
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

########################
# NAT GATEWAY (1)
# - needs an Elastic IP
# - must live in a public subnet (use public[0])
########################
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    { Name = "lab-nat-eip" }
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.tags,
    { Name = "lab-nat" }
  )

  depends_on = [aws_internet_gateway.this]
}

########################
# PRIVATE ROUTE TABLE
# - default route to NAT Gateway
########################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(
    var.tags,
    { Name = "lab-private-rt" }
  )
}

########################
# PRIVATE ROUTE TABLE ASSOCIATION
########################
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
