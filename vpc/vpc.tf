
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
# # Create NAT Gateway for each VPC
# resource "aws_eip" "nat_eip" {
#   count  = var.create_vpc
#   domain = "vpc"
# }

# # Create NAT Gateway in each VPC
# resource "aws_nat_gateway" "nat" {
#   count = var.create_vpc

#   allocation_id = aws_eip.nat_eip[count.index].id
#   subnet_id     = aws_subnet.public[count.index * var.public_subnets_per_vpc].id

#   tags = {
#     Name = "nat-gw-${count.index}"
#   }
# }

# Create private route tables and associate with NAT gateway
# resource "aws_route_table" "private_rt" {
#   count = var.create_vpc

#   vpc_id = aws_vpc.multi_vpc[count.index].id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat[count.index].id
#   }

#   tags = {
#     Name = "private-rt-${count.index}"
#   }
# }

# # Associate private subnets with the private route table

# resource "aws_route_table_association" "private_assoc" {
#   count = length(var.private_subnet_cidrs)

#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private_rt[
#     floor(count.index / var.private_subnets_per_vpc)
#   ].id
# }

# ============== NAT GATEWAY PER AVAILABILITY ZONE ==============
locals {
  unique_public_azs = distinct(var.public_subnet_azs)

  private_subnets_indexed = {
    for idx, sn in aws_subnet.private :
    tostring(idx) => sn.id
  }

  public_subnets_by_az = {
    for sn in aws_subnet.public :
    sn.availability_zone => sn.id
  }

  nat_by_az = {
    for az, nat in aws_nat_gateway.nat :
    az => nat.id
  }
}

resource "aws_eip" "nat_eip" {
  for_each = toset(local.unique_public_azs)
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat" {
  for_each = toset(local.unique_public_azs)

  allocation_id = aws_eip.nat_eip[each.key].id

  subnet_id = (
    element([
      for i, sn in aws_subnet.public :
      sn.id if sn.availability_zone == each.key
    ], 0)
  )

  tags = {
    Name = "nat-${each.key}"
  }
}
# ============== private route tables for private subnet ==============
resource "aws_route_table" "private_rt" {
  for_each = local.private_subnets_indexed

  vpc_id = aws_vpc.multi_vpc[
    floor(tonumber(each.key) / var.private_subnets_per_vpc)
  ].id

  route {
    cidr_block = "0.0.0.0/0"

    nat_gateway_id = local.nat_by_az[
      aws_subnet.private[tonumber(each.key)].availability_zone
    ]
  }

  tags = {
    Name = "private-rt-${each.key}"
  }
}
# ============== associate private subnets with private route tables ==============
resource "aws_route_table_association" "private_assoc" {
  for_each = local.private_subnets_indexed

  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt[each.key].id
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


############################################################
# VPC ENDPOINTS FOR PRIVATE EKS (FINAL FIXED VERSION)
############################################################

data "aws_region" "current" {}

locals {
  vpc_keys = {
    for i in range(var.create_vpc) :
    tostring(i) => i
  }

  interface_services = [
    "ssm",
    "ssmmessages",
    "ec2messages",
    "ecr.api",
    "ecr.dkr",
    "sts"
  ]
}

############################################################
# SECURITY GROUP FOR VPC ENDPOINTS (one per VPC)
############################################################
resource "aws_security_group" "vpce_sg" {
  for_each = local.vpc_keys

  name        = "vpce-sg-${each.key}"
  description = "VPC Endpoint security group"
  vpc_id      = aws_vpc.multi_vpc[each.value].id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidrs[each.value]]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################################
# INTERFACE ENDPOINTS FOR SSM, ECR, STS, EC2 MSG, SSM MSG
############################################################

# Build a FLAT LIST of all combinations
locals {
  interface_matrix = flatten([
    for vpc_key, vpc_index in local.vpc_keys : [
      for svc in local.interface_services : {
        key       = "${vpc_key}-${svc}"
        vpc_index = vpc_index
        svc       = svc
      }
    ]
  ])

  # Convert list → map for for_each
  interface_map = {
    for item in local.interface_matrix :
    item.key => item
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_map

  vpc_id            = aws_vpc.multi_vpc[each.value.vpc_index].id
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.${data.aws_region.current.id}.${each.value.svc}"


  # all private subnets in this VPC
  subnet_ids = [
    for sn in aws_subnet.private :
    sn.id if sn.vpc_id == aws_vpc.multi_vpc[each.value.vpc_index].id
  ]

  security_group_ids = [
    aws_security_group.vpce_sg[tostring(each.value.vpc_index)].id
  ]

  private_dns_enabled = true

  tags = {
    Name = "vpce-${each.value.svc}-vpc-${each.value.vpc_index}"
  }
}


############################################################
# S3 GATEWAY ENDPOINT (Private Route Tables)
############################################################
resource "aws_vpc_endpoint" "s3" {
  for_each = local.vpc_keys

  vpc_id            = aws_vpc.multi_vpc[each.value].id
  vpc_endpoint_type = "Gateway"
  service_name = "com.amazonaws.${data.aws_region.current.id}.s3"

  route_table_ids = [
    for rt in aws_route_table.private_rt :
    rt.id if rt.vpc_id == aws_vpc.multi_vpc[each.value].id
  ]
}
