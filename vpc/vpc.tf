resource "aws_vpc" "multi_vpc" {
  count                = var.create_vpc
  cidr_block           = var.vpc_cidrs[count.index]
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "nbsl-${var.vpc_names[count.index]}"
  }
}


resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.multi_vpc[
    floor(count.index / var.public_subnets_per_vpc)
  ].id

  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone = var.public_subnet_azs[count.index]

  tags = {
    Name = "public-subnet-${count.index}"
    Type = "public"
  }
}


resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.multi_vpc[
    floor(count.index / var.private_subnets_per_vpc)
  ].id

  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.private_subnet_azs[count.index]

tags = {
    Name = "private-subnet-${count.index}"
    Type = "private"

    # Internal load balancers
    "kubernetes.io/role/internal-elb" = 1

    # Correct cluster tag per VPC
    "kubernetes.io/cluster/${var.cluster_names[floor(count.index / var.private_subnets_per_vpc)]}" = "shared"
  }
}

resource "aws_internet_gateway" "igw" {
  count  = var.create_vpc
  vpc_id = aws_vpc.multi_vpc[count.index].id

  tags = {
    Name = "igw-${count.index}"
  }
}

resource "aws_eip" "nat_eip" {
  count  = var.create_vpc
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count = var.create_vpc

  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index * var.public_subnets_per_vpc].id

  tags = {
    Name = "nat-gw-${count.index}"
  }
}

resource "aws_route_table" "public_rt" {
  count = var.create_vpc

  vpc_id = aws_vpc.multi_vpc[count.index].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[count.index].id
  }

  tags = {
    Name = "public-rt-${count.index}"
  }
}


resource "aws_route_table_association" "public_assoc" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt[
    floor(count.index / var.public_subnets_per_vpc)
  ].id
}

resource "aws_route_table" "private_rt" {
  count = var.create_vpc

  vpc_id = aws_vpc.multi_vpc[count.index].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private_assoc" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[
    floor(count.index / var.private_subnets_per_vpc)
  ].id
}


#

