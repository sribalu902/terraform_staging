variable "vpc_ids" {
  type        = list(string)
  description = "List of VPC IDs (dynamic)"
}

variable "private_subnet_ids" {
  type        = list(list(string))
  description = "List of PRIVATE subnets grouped by VPC"
}

variable "vpc_indexes" {
  description = "List of VPC indexes: [0,1,2...]"
  type        = list(string)
}

variable "allowed_sg_ids" {
  description = "List of lists. SGs allowed per VPC"
  type        = list(list(string))
}

variable "identifier_prefix" {
  type        = string
  default     = "pg-db"
}

variable "db_name" {
  description = "Initial Postgres database name"
  type        = string
  default     = "cds_db"
}

variable "username" {
  description = "Master username for Postgres"
  type        = string
}

variable "password" {
  description = "Master password for Postgres"
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "Postgres engine version"
  type        = string
  default     = "17.7"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage size (GB)"
  type        = number
  default     = 20
}

variable "publicly_accessible" {
  description = "Whether RDS should be publicly accessible (dev only)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting the DB"
  type        = bool
  default     = true
}
