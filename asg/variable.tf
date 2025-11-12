variable "ami_id" {
  description = "The AMI ID for the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the EC2 instances"
  type        = string
  default     = "t2.micro"
  
}

variable "key_name" {
  description = "The key pair name for SSH access"
  type        = string
}
variable "vpc_security_group_ids" {
  description = "List of VPC Security Group IDs"
  type        = list(string)
}

variable "aws_subnet_ids" {
  description = "List of Subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "desired_capacity" {
  description = "The desired capacity of the Auto Scaling Group"
  type        = number
  
}

variable "max_size" {
  description = "The maximum size of the Auto Scaling Group"
  type        = number

}

variable "min_size" {
  description = "The minimum size of the Auto Scaling Group"
  type        = number
  
}