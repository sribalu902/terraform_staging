############################################
# VPC CONFIGURATION
############################################

# Number of VPCs to create
create_vpc = 1

# Friendly names for each VPC (index-based)
vpc_names = [
  "prod-test",
  # "bap"
]

# EKS cluster names (one per VPC)
cluster_names = [
  "prod-test-eks",
  # "bap"
]

# CIDRs per VPC (match count)
vpc_cidrs = [
  "10.0.0.0/16",
  # "10.1.0.0/16"
]

# Public Subnets (2 per VPC)
public_subnet_cidrs = [
  "10.0.20.0/24", "10.0.21.0/24","10.0.22.0/24",
  # "10.1.1.0/24", "10.1.2.0/24"
]

# Private Subnets (2 per VPC)
private_subnet_cidrs = [
  "10.0.30.0/24", "10.0.31.0/24","10.0.32.0/24"
  # "10.1.11.0/24", "10.1.12.0/24"
]

# Number of public / private subnets per VPC
public_subnets_per_vpc  = 3
private_subnets_per_vpc = 3

# Availability Zones for public subnets
public_subnet_azs = [
  "ap-south-1a", "ap-south-1b","ap-south-1c",
  # "ap-south-1a", "ap-south-1b"
]

# AZs for private subnets
private_subnet_azs = [
  "ap-south-1a", "ap-south-1b","ap-south-1c",
  # "ap-south-1a", "ap-south-1b"
]


############################################
# EKS CONFIGURATION
############################################

cluster_name_prefix = "prod-test"

# Upgrade to EKS 1.33
eks_version = "1.33"

# Optional SSH key for worker nodes
node_ssh_key_name = "demo-key"

############################################
# MANAGED NODE GROUPS (DYNAMIC)
############################################

node_groups = [
  {
    name           = "system-ng"
    instance_types = ["t3.medium"]
    desired_size   = 2
    min_size       = 1
    max_size       = 3
    disk_size      = 20
    ami_type       = "AL2023_x86_64_STANDARD"

    labels = {
      role = "system"
    }
  },
  # {
  #   name           = "app-ng"
  #   instance_types = ["t3.medium"]
  #   desired_size   = 2
  #   min_size       = 2
  #   max_size       = 6
  #   disk_size      = 25
  #   ami_type       = "AL2023_x86_64_STANDARD"

  #   labels = {
  #     role = "application"
  #   }
  # }

  # OPTIONAL – enable later if needed
  # {
  #   name           = "spot-ng"
  #   instance_types = ["m5.large", "m5a.large", "t3.large"]
  #   desired_size   = 2
  #   min_size       = 1
  #   max_size       = 4
  #   disk_size      = 20
  #   capacity_type  = "SPOT"
  #
  #   labels = {
  #     lifecycle = "spot"
  #   }
  # }
]

############################################
# EKS ADDONS (EKS 1.33 COMPATIBLE)
############################################

addons = [
  {
    name    = "vpc-cni"
    version = "v1.19.2-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.12.2-eksbuild.4"
  },
  {
    name    = "kube-proxy"
    version = "v1.33.0-eksbuild.2"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.46.0-eksbuild.1"
  }
]


############################################
# COMMON TAGS
############################################

tags = {
  Environment = "stage"
  Project     = "nbsl"
  Owner       = "bala"
}

environment = "demo-key"



############################################
# BASTION HOST CONFIGURATION
############################################

ssh_cidr        = "192.168.68.101/32"      # your laptop IP
bastion_ami_id  = "ami-087d1c9a513324697"   # ubuntu
bastion_key_name = "demo-key"


# ############################################
# # EC2 INSTANCE MODULE (per VPC)
# ############################################

# ami_ids = [
#   "ami-01ca13db604661046",    # for EC2 in VPC[0]
#   # "ami-02b8269d5e85954ef"     # for EC2 in VPC[1]
# ]

# instance_types = [
#   "t3.medium",
#   # "t3.small"
# ]

# key_name_ec2 = "demo-key"

# # Create EC2s in these VPC indices
# ec2_vpc_index_list = [
#   0,
#   # 1
# ]

# ec2_instance_names = [
#   "cds-nbsl",
#   # "bap-nbsl"
# ]
