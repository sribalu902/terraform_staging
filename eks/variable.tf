variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for EKS worker nodes"
}

variable "worker_sg_id" {
  type        = string
  description = "Security group for worker nodes created by security_group_eks module"
}

variable "eks_version" {
  type    = string
  default = "1.27"
}

variable "node_ssh_key_name" {
  type    = string
  default = ""
}

variable "node_groups" {
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

variable "tags" {
  type    = map(string)
  default = {}
}

variable "node_group_tags" {
  type    = map(string)
  default = {}
}
