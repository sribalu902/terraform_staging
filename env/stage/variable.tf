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
#########################################
# EKS VARIABLES — ROOT MODULE
#########################################





variable "node_ami" {
  type = string
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "key_name" {
  type    = string
  default = ""
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

#########################################
# EC2 VARIABLES — ROOT MODULE
#########################################

variable "ami_ids" {
  description = "List of AMI IDs to use for EC2 instances"
  type        = list(string)
}

variable "instance_types" {
  description = "List of instance types for EC2 instances"
  type        = list(string)
}

variable "ec2_instance_names" {
  description = "List of EC2 instance names"
  type        = list(string)
}

variable "key_name_ec2" {
  description = "EC2 key pair name"
  type        = string
}

variable "ec2_vpc_index_list" {
  description = "Indices of VPCs where EC2 should be created"
  type        = list(number)
}

variable "admin_user_arn" {
  type    = string
  default = ""
}
variable "admin_role_arn" {
  type = string
  default = ""
}




