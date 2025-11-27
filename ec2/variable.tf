variable "ami_ids" {
  type = list(string)
}

variable "instance_types" {
  type = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs from VPC module"
  type        = list(string)
}


variable "key_name" {
  type = string
}

variable "ec2_instance_names" {
  type = list(string)
}


variable "sg_ids" {
  description = "Flattened SG list for EC2"
  type        = list(string)
}