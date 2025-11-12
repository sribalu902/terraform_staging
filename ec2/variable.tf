variable "ami_ids" {
  description = "List of AMI IDs for the EC2 instances"
  type        = list(string)
  
}

variable "instance_types" {
  description = "List of instance types for the EC2 instances"
  type        = list(string)


}

variable "subnet_id" {
  description = "List of subnet IDs for the EC2 instances"
  type        = list(object({
    id = string}))
}
variable "security_group_ids" {
  description = "List of security group IDs to associate with the EC2 instances"
  type        = list(string)
  
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  
}
variable "ec2_instance_names" {
  description = "List of names for the EC2 instances"
  type        = list(string)
  
}