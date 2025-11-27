############################################
# VPC CONFIGURATION
############################################

# Number of VPCs to create
create_vpc = 2

# Friendly names for each VPC (index-based)
vpc_names = [
  "cds",
  "bap"
]

# EKS cluster names (one per VPC)
cluster_names = [
  "cds",
  "bap"
]

# CIDRs per VPC (match count)
vpc_cidrs = [
  "10.0.0.0/16",
  "10.1.0.0/16"
]

# Public Subnets (2 per VPC)
public_subnet_cidrs = [
  "10.0.1.0/24", "10.0.2.0/24",
  "10.1.1.0/24", "10.1.2.0/24"
]

# Private Subnets (2 per VPC)
private_subnet_cidrs = [
  "10.0.11.0/24", "10.0.12.0/24",
  "10.1.11.0/24", "10.1.12.0/24"
]

# Number of public / private subnets per VPC
public_subnets_per_vpc  = 2
private_subnets_per_vpc = 2

# Availability Zones for public subnets
public_subnet_azs = [
  "ap-south-1a", "ap-south-1b",
  "ap-south-1a", "ap-south-1b"
]

# AZs for private subnets
private_subnet_azs = [
  "ap-south-1a", "ap-south-1b",
  "ap-south-1a", "ap-south-1b"
]


############################################
# EKS CONFIGURATION
############################################

cluster_name_prefix = "nbsl"

eks_version = "1.29"

# (Optional) SSH key for worker nodes
node_ssh_key_name = "stage"

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
  },
  {
    name           = "app-ng"
    instance_types = ["t3.large"]
    desired_size   = 2
    min_size       = 2
    max_size       = 6
    disk_size      = 40
  }
  # {
  #   name           = "spot-ng"
  #   instance_types = ["m5.large"]
  #   desired_size   = 2
  #   min_size       = 1
  #   max_size       = 4
  #   disk_size      = 20
  #   capacity_type  = "SPOT"
  # }
]





############################################
# ADMIN USERS FOR KUBECTL ACCESS
############################################
admin_user_arns = [
  "arn:aws:iam::268428819515:user/bala-admin"
]


############################################
# COMMON TAGS
############################################

tags = {
  Environment = "stage"
  Project     = "nbsl"
  Owner       = "bala"
}

environment = "stage"



############################################
# BASTION HOST CONFIGURATION
############################################

ssh_cidr        = "122.177.244.209/32"      # your laptop IP
bastion_ami_id  = "ami-02b8269d5e85954ef"   # Amazon Linux 2
bastion_key_name = "stage"


############################################
# EC2 INSTANCE MODULE (per VPC)
############################################

ami_ids = [
  "ami-02b8269d5e85954ef",    # for EC2 in VPC[0]
  "ami-02b8269d5e85954ef"     # for EC2 in VPC[1]
]

instance_types = [
  "t3.small",
  "t3.small"
]

key_name_ec2 = "stage"

# Create EC2s in these VPC indices
ec2_vpc_index_list = [
  0,
  1
]

ec2_instance_names = [
  "cds-nbsl",
  "bap-nbsl"
]
