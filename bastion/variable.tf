
# Bastion module variables
variable "vpc_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(list(string))
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "ssh_cidr" {
  type = string
  description = "Your laptop IP for SSH"
}

