variable "vpc_id" {
  description = "The ID of the VPC where the security group will be created"
  type        = string
}

variable "public-sg" {
  description = "Name of the security group for EC2 instances in the public subnet"
  type        = string
  default     = "ec2-public-sg"
}