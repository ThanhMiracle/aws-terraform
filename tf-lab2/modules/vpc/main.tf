#############################################
# modules/vpc/main.tf (COMPLETE)
# - VPC + IGW
# - 2 Public subnets + Public route table
# - 2 Private subnets + NAT Gateway + Private route table
# - Tags everywhere
# - NAT depends_on IGW (prevents race)
#############################################

#############################################
# 1) VPC
#############################################
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

#############################################
# 2) Internet Gateway (IGW)
#############################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

#############################################
# 3) Public Subnets (2)
#############################################
resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Tier = "public"
  })
}

#############################################
# 4) Private Subnets (2)
#############################################
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  # (default is false) but explicit is nice
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Tier = "private"
  })
}

#############################################
# 5) Elastic IP (EIP) for NAT Gateway
#############################################
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}

#############################################
# 6) NAT Gateway (in PUBLIC subnet 1)
#############################################
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  # Prevent timing/race issues
  depends_on = [aws_internet_gateway.igw]

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })
}

#############################################
# 7) Public Route Table -> IGW
#############################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

#############################################
# 8) Associate Public RT to Public Subnets
#############################################
resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#############################################
# 9) Private Route Table -> NAT
#############################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt"
  })
}

#############################################
# 10) Associate Private RT to Private Subnets
#############################################
resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

#############################################
# 11) Security Group: Bastion (Public EC2)
# - Allow SSH only from your IP (YOUR_IP/32)
#############################################
resource "aws_security_group" "bastion" {
  name        = "${var.name}-bastion-sg-only-my-ip"
  description = "Allow SSH to bastion only from my IP"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_ip]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-bastion-sg"
  })
}

#############################################
# 12) Security Group: Private EC2
# - Allow SSH ONLY from bastion SG (best practice)
#############################################
resource "aws_security_group" "private_ec2" {
  name        = "${var.name}-private-ec2-sg"
  description = "Allow SSH to private EC2 only from bastion"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "SSH from bastion SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-ec2-sg"
  })
}