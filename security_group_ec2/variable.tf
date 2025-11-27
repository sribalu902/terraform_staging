variable "vpc_ids" {
  description = "List of VPC IDs — one SG will be created per VPC"
  type        = list(string)
}

variable "sg_name_prefix" {
  description = "Prefix for the SG name"
  type        = string
  default     = "public-sg"
}
