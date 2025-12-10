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


##############################
# EKS SPECIFIC VARIABLES
##############################

variable "cluster_name_prefix" {
  type = string
}

variable "eks_version" {
  type    = string
  default = "1.27"
}

# (Optional SSH access to worker nodes)
variable "node_ssh_key_name" {
  type    = string
  default = ""
}

##############################
# DYNAMIC NODE GROUPS
##############################

variable "node_groups" {
  description = "List of dynamic node groups per EKS cluster"
  type = list(object({
    name           = string
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    labels         = optional(map(string), {})
    taints         = optional(list(object({
                      key    = string
                      value  = string
                      effect = string
                    })), [])
    capacity_type  = optional(string, "ON_DEMAND")
    max_unavailable = optional(number, 1)
  }))
}


##########################
# ADMIN USER ARNS FOR EKS CLUSTER
##########################
variable "admin_user_arns" {
  type    = list(string)
  default = []
}

variable "admin_role_arn" {
  type    = string
  default = ""
}
##############################
# TAGS (COMMON TAGGING)
##############################

variable "tags" {
  type    = map(string)
  default = {}
}

variable "environment" {
  type    = string
  default = "stage"
}


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

##########################################
#ec2 instance variables
##########################################
variable "ami_ids" {
  type = list(string)
}

variable "instance_types" {
  type = list(string)
}


variable "key_name_ec2" {
  description = "value"
  type = string
}

variable "ec2_instance_names" {
  description = "value"
  type = list(string)
}


variable "ec2_vpc_index_list" {
  description = "List of VPC indices where EC2 instances should be created"
  type        = list(number)
}





