##########################################
# VPC VARIABLES — ROOT MODULE
##########################################
variable "create_vpc" {
  type = number
}

variable "vpc_names" {
  description = "Friendly names for VPCs in order (index 0 => vpc_names[0])"
  type        = list(string)
}

variable "cluster_names" {
  description = "Cluster names mapping per VPC (used for tagging). Order must match vpc_names."
  type        = list(string)
}

variable "vpc_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnets_per_vpc" {
  type = number
}

variable "private_subnets_per_vpc" {
  type = number
}
variable "public_subnet_azs" {
  description = "Availability zones for public subnets"
  type        = list(string)
}
variable "private_subnet_azs" {
  description = "Availability zones for private subnets"
  type        = list(string)
}
#

###############################################
# REQUIRED: Dynamic VPC module outputs
###############################################

variable "vpc_indexes" {
  description = "List of VPC indexes for which RDS should be created (example: [\"0\"] for 1 VPC)"
  type        = list(string)
}

###############################################
# RDS Instance Configuration
###############################################

variable "identifier_prefix" {
  description = "Prefix to use for naming each dynamic RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the initial Postgres database"
  type        = string
  default     = "cds_db"
}

variable "username" {
  description = "Master username for Postgres instance"
  type        = string
}

variable "password" {
  description = "Master password for Postgres instance"
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "Version of the Postgres engine"
  type        = string
  default     = "17.7"
}

variable "instance_class" {
  description = "Instance type for RDS (dev: db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage size (GB)"
  type        = number
  default     = 20
}

variable "publicly_accessible" {
  description = "Whether the DB should be publicly accessible (DEV ONLY)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on RDS deletion"
  type        = bool
  default     = true
}

# ###############################################
# # SECURITY GROUP INPUTS (will come from modules)
# ###############################################

# variable "ecs_sg_id" {
#   description = "Security Group ID for ECS tasks"
#   type        = string
# }

# variable "kafka_sg_id" {
#   description = "Security Group ID for Kafka EC2 instance"
#   type        = string
# }

# variable "bastion_sg_ids" {
#   description = "List of Bastion SGs (one per VPC)"
#   type        = list(string)
# }

#####################################################
# BASTION VARIABLES
#####################################################

# Laptop IP → for SSH to bastion
variable "ssh_cidr" {
  type        = string
  description = "Your public IP for SSH access (x.x.x.x/32)"
}

# AMI for bastion (Amazon Linux 2)
variable "bastion_ami_id" {
  type        = string
  description = "AMI ID for bastion servers"
}

# Key pair to use for all bastion hosts
variable "bastion_key_name" {
  type        = string
  description = "Key pair name used to SSH bastion"
}


############################################
# ECS Cluster Variables
############################################

variable "cluster_name" {
  type        = string
  description = "Name of ECS cluster"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for ECS resources"
}

variable "kafka_ami_id" {
  type        = string
  description = "AMI for Kafka EC2"
}

variable "kafka_instance_type" {
  type        = string
  description = "Instance type for Kafka EC2"
  default     = "t3.large"
}

variable "kafka_key_name" {
  type        = string
  description = "SSH Key for Kafka EC2"
}

variable "kafka_asg_desired" {
  type = number
}

variable "kafka_asg_min" {
  type = number
}

variable "kafka_asg_max" {
  type = number
}
