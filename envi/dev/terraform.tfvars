
############################################
# VPC CONFIGURATION
############################################

# Number of VPCs to create
create_vpc = 1

# Friendly names for each VPC (index-based)
vpc_names = [
  "cds",
  # "bap"
]

# EKS cluster names (one per VPC)
cluster_names = [
  "cds",
  # "bap"
]

# CIDRs per VPC (match count)
vpc_cidrs = [
  "10.0.0.0/16",
  # "10.1.0.0/16"
]

# Public Subnets (2 per VPC)
public_subnet_cidrs = [
  "10.0.1.0/24", "10.0.2.0/24",
  # "10.1.1.0/24", "10.1.2.0/24"
]

# Private Subnets (2 per VPC)
private_subnet_cidrs = [
  "10.0.11.0/24", "10.0.12.0/24",
  # "10.1.11.0/24", "10.1.12.0/24"
]

# Number of public / private subnets per VPC
public_subnets_per_vpc  = 2
private_subnets_per_vpc = 2

# Availability Zones for public subnets
public_subnet_azs = [
  "ap-south-1a", "ap-south-1b",
  # "ap-south-1a", "ap-south-1b"
]

# AZs for private subnets
private_subnet_azs = [
  "ap-south-1a", "ap-south-1b",
  # "ap-south-1a", "ap-south-1b"
]

#########################################################
# Dynamic RDS - Which VPCs get a DB?
#########################################################

vpc_indexes = ["0"]

#########################################################
# RDS instance configuration
#########################################################

identifier_prefix = "cds-postgres"

db_name  = "cds_db"
username = "cds_admin"
password = "DBpossword123"

engine_version     = "17.7"
instance_class     = "db.t3.micro"
allocated_storage  = 20

publicly_accessible = false
skip_final_snapshot = true


############################################
# BASTION HOST CONFIGURATION
############################################

ssh_cidr        = "183.82.7.231/32"      # your laptop IP
bastion_ami_id  = "ami-02b8269d5e85954ef"   # Amazon Linux 2
bastion_key_name = "stage"


############################################
# ECS Cluster Settings
############################################

cluster_name = "dev-ecs"
name_prefix  = "dev"

kafka_ami_id        = "ami-02b8269d5e85954ef"    # Ubuntu 22.04 or ECS Optimized
kafka_instance_type = "t3.micro"
kafka_key_name      = "stage"

kafka_asg_desired = 1
kafka_asg_min     = 1
kafka_asg_max     = 1



