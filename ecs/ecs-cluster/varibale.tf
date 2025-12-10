variable "cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "bastion_sg_ids" {
  type = list(string)
}

#####################################
# EC2 HOST VARIABLES
#####################################

variable "ami_id" {
  description = "AMI for Kafka EC2 host"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "key_name" {
  type        = string
  description = "SSH key for Kafka EC2"
}

variable "asg_desired" {
  type = number
}

variable "asg_min" {
  type = number
}

variable "asg_max" {
  type = number
}
