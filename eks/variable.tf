variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_security_group_ids" {
  type = list(string)
}

variable "worker_sg_id" {
  type = string
}

variable "node_ssh_key_name" {
  type    = string
  default = ""
}

variable "node_groups" {
  type = list(object({
    name           = string
    instance_types = list(string)
    disk_size      = number
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = optional(string)
    ami_type       = optional(string)
    labels         = optional(map(string))
    max_unavailable = optional(number)
  }))
}

variable "eks_version" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "node_group_tags" {
  type = map(string)
  default = {}
}

variable "default_ami_type" {
  type    = string
  default = "AL2_x86_64"
}