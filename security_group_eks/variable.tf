variable "create_vpc" {
  type = number
}

variable "vpc_ids" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
