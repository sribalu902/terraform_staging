#to define variables for subnet cidrs and availability zones

variable "create_vpc" {
  description = "How many VPCs to create (1 or 2)"
  type        = number
}

variable "vpc_cidrs" {
  description = "CIDR blocks for VPCs"
  type        = list(string)
}
variable "vpc_names" {
  description = "Name of the EKS cluster"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs for all VPCs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs for all VPCs"
  type        = list(string)
}

variable "public_subnets_per_vpc" {
  description = "Number of public subnets per VPC"
  type        = number
  default     = 2
}

variable "public_subnet_azs" {
  description = "Availability zones for public subnets"
  type        = list(string)
}

variable "private_subnet_azs" {
  description = "Availability zones for private subnets"
  type        = list(string)

}

variable "private_subnets_per_vpc" {
  description = "Number of private subnets per VPC"
  type        = number
  default     = 2
}

variable "cluster_names" {
  type = list(string)
  description = "Cluster names for each VPC (same length as vpc_cidrs)"
}

## End of variables.tf