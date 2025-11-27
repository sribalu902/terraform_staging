
# Create multiple VPCs based on the provided variable
resource "aws_vpc" "multi_vpc" {
  count                = var.create_vpc
  cidr_block           = var.vpc_cidrs[count.index]
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "nbsl-${var.vpc_names[count.index]}"
  }
}

# Create public subnets in each VPC
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

    # REQUIRED FOR EKS (ALB, NLB, and ENIs)
    "kubernetes.io/role/elb" = "1"

    # REQUIRED SO EKS KNOWS THIS SUBNET BELONGS TO THE CLUSTER
    "kubernetes.io/cluster/${var.cluster_names[floor(count.index / var.public_subnets_per_vpc)]}" = "shared"
}

}

# Create private subnets in each VPC
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
    "kubernetes.io/role/internal-elb" = "1"

    # Correct cluster tag per VPC
    "kubernetes.io/cluster/${var.cluster_names[floor(count.index / var.private_subnets_per_vpc)]}" = "shared"
  }
}

# Create Internet Gateway for each VPC

resource "aws_internet_gateway" "igw" {
  count  = var.create_vpc
  vpc_id = aws_vpc.multi_vpc[count.index].id

  tags = {
    Name = "igw-${count.index}"
  }
}

# Create NAT Gateway for each VPC
resource "aws_eip" "nat_eip" {
  count  = var.create_vpc
  domain = "vpc"
}

# Create NAT Gateway in each VPC
resource "aws_nat_gateway" "nat" {
  count = var.create_vpc

  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index * var.public_subnets_per_vpc].id

  tags = {
    Name = "nat-gw-${count.index}"
  }
}

# Create Route Tables and Associations
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

# Associate public subnets with the public route table

resource "aws_route_table_association" "public_assoc" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt[
    floor(count.index / var.public_subnets_per_vpc)
  ].id
}

# Create private route tables and associate with NAT gateway
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

# Associate private subnets with the private route table

resource "aws_route_table_association" "private_assoc" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[
    floor(count.index / var.private_subnets_per_vpc)
  ].id
}

# Create Network ACLs for public subnets
resource "aws_network_acl" "public_nacl" {
  count  = var.create_vpc
  vpc_id = aws_vpc.multi_vpc[count.index].id

  tags = {
    Name = "public-nacl-${var.vpc_names[count.index]}"
  }
}

# Create Network ACLs for private subnets
resource "aws_network_acl" "private_nacl" {
  count  = var.create_vpc
  vpc_id = aws_vpc.multi_vpc[count.index].id

  tags = {
    Name = "private-nacl-${var.vpc_names[count.index]}"
  }
}


# Create Network ACL rules for public NACL inbound
resource "aws_network_acl_rule" "public_allow_all_inbound" {
  count          = var.create_vpc
  network_acl_id = aws_network_acl.public_nacl[count.index].id

  rule_number = 100
  egress      = false
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
}

# Create Network ACL rules for public NACL outbound
resource "aws_network_acl_rule" "public_allow_all_outbound" {
  count          = var.create_vpc
  network_acl_id = aws_network_acl.public_nacl[count.index].id

  rule_number = 100
  egress      = true
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
}

# Create Network ACL rules for private NACL inbound
resource "aws_network_acl_rule" "private_allow_vpc_inbound" {
  count          = var.create_vpc
  network_acl_id = aws_network_acl.private_nacl[count.index].id

  rule_number = 100
  egress      = false
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = var.vpc_cidrs[count.index]
}

# Create Network ACL rules for private NACL outbound
resource "aws_network_acl_rule" "private_allow_all_outbound" {
  count          = var.create_vpc
  network_acl_id = aws_network_acl.private_nacl[count.index].id

  rule_number = 100
  egress      = true
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
}

# Associate Network ACLs with public subnets
resource "aws_network_acl_association" "public_assoc" {
  count = length(var.public_subnet_cidrs)

  subnet_id = aws_subnet.public[count.index].id

  network_acl_id = aws_network_acl.public_nacl[
    floor(count.index / var.public_subnets_per_vpc)
  ].id
}

# Associate Network ACLs with private subnets
resource "aws_network_acl_association" "private_assoc" {
  count = length(var.private_subnet_cidrs)

  subnet_id = aws_subnet.private[count.index].id

  network_acl_id = aws_network_acl.private_nacl[
    floor(count.index / var.private_subnets_per_vpc)
  ].id
}


