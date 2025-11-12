#to define variables for subnet cidrs and availability zones
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}
variable "public_subnet_azs" {
  description = "List of availability zones for public subnets"
  type        = list(string)
  
}
variable "private_subnet_azs" {
  description = "List of availability zones for private subnets"
  type        = list(string)
  
}