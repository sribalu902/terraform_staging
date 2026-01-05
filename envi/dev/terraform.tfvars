
############################################
# VPC CONFIGURATION
############################################

# Number of VPCs to create
create_vpc = 1

# Friendly names for each VPC (index-based)
vpc_names = [
  "UAT",
  # "bap"
]

# EKS cluster names (one per VPC)
cluster_names = [
  "UAT-ECS",
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
bastion_ami_id  = "ami-087d1c9a513324697"   
bastion_key_name = "demo-key"


############################################
# ECS Cluster Settings
############################################

cluster_name = "dev-ecs"
name_prefix  = "dev"

# kafka_ami_id        = "ami-085c0dc6d1e93db96"    # Amazon Linux 2 ECS Optimized
kafka_instance_type = "t2.large"
kafka_key_name      = "demo-key"

kafka_asg_desired = 2
kafka_asg_min     = 1
kafka_asg_max     = 4


# ############################################
# # REDIS SERVICE CONFIG
# ############################################
# redis_cpu          = 256
# redis_memory       = 512
# redis_port         = 6379

# ############################################
# # KAFKA SERVICE CONFIG
# ############################################
# kafka_cpu            = 512
# kafka_memory         = 1024

# ############################################
# # kafka -UI 
# ############################################
# kafka_ui_cpu    = 256
# kafka_ui_memory = 512
# kafka_ui_port   = 8080


# ############################################
# # ONIX ADAPTER CONFIG
# ############################################

# onix_cpu    = 512
# onix_memory = 1024
# onix_port   = 8002




