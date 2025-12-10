#############################################
# VPC & NETWORK VARIABLES
#############################################

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Prefix for all resource names"
  type        = string
  default     = "demo-ecs"
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR range for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_a" {
  description = "Primary availability zone"
  type        = string
  default     = "ap-south-1a"
}

variable "az_b" {
  description = "Secondary availability zone"
  type        = string
  default     = "ap-south-1b"
}


#############################################
# COMPUTE VARIABLES
# (EC2, Bastion, Kafka hosts)
#############################################

variable "key_name" {
  description = "Name of SSH Key Pair"
  type        = string
}

variable "bastion_instance_type" {
  description = "Instance type for Bastion host"
  type        = string
  default     = "t3.micro"
}

variable "kafka_instance_type" {
  description = "EC2 instance type for Kafka broker"
  type        = string
  default     = "t3.large"
}

variable "kafka_desired_count" {
  description = "Number of Kafka EC2 nodes"
  type        = number
  default     = 1
}

variable "bastion_ami" {
  description = "AMI ID for Ubuntu bastion"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}


#############################################
# ECS VARIABLES (Cluster, Task sizing, Ports)
#############################################

variable "onix_container_port" {
  description = "Port exposed by the Onix plugin container"
  type        = number
  default     = 8002
}

variable "kafka_ui_container_port" {
  description = "External port exposed by Kafka UI on ALB"
  type        = number
  default     = 8081
}

variable "cds_container_port" {
  description = "Container port where CDS application runs"
  type        = number
  default     = 8080
}

variable "redis_container_port" {
  description = "Container port for Redis service"
  type        = number
  default     = 6379
}

#############################################
# CPU & Memory Sizing for Each Task
#############################################

variable "onix_cpu" {
  description = "CPU units reserved for Onix plugin task"
  type        = number
  default     = 512
}

variable "onix_memory" {
  description = "Memory (MiB) for Onix plugin task"
  type        = number
  default     = 1024
}

variable "kafka_ui_cpu" {
  description = "CPU units reserved for Kafka UI Fargate task"
  type        = number
  default     = 256
}

variable "kafka_ui_memory" {
  description = "Memory (MiB) for Kafka UI task"
  type        = number
  default     = 512
}

variable "cds_cpu" {
  description = "CPU units reserved for CDS Fargate task"
  type        = number
  default     = 1024
}

variable "cds_memory" {
  description = "Memory (MiB) for CDS task"
  type        = number
  default     = 2048
}

variable "redis_cpu" {
  description = "CPU units for Redis Fargate task"
  type        = number
  default     = 256
}

variable "redis_memory" {
  description = "Memory (MiB) for Redis task"
  type        = number
  default     = 512
}

#############################################
# Load Balancer (ALB) Options
#############################################

variable "create_alb" {
  description = "Whether to create ALB for Onix & Kafka UI"
  type        = bool
  default     = true
}


#############################################
# DATABASE (RDS Postgres)
#############################################

variable "db_username" {
  description = "Postgres DB user"
  type        = string
  default     = "cdsuser"
}

variable "db_password" {
  description = "Postgres DB password (use tfvars)"
  type        = string
}

variable "db_name" {
  description = "Initial DB name"
  type        = string
  default     = "cds_db"
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage (GB)"
  type        = number
  default     = 20
}


#############################################
# CONTAINER IMAGES
#############################################

variable "onix_image" {
  description = "ECR image for Onix plugin"
  type        = string
}

variable "kafka_ui_image" {
  description = "Image for Kafka UI"
  type        = string
  default     = "provectuslabs/kafka-ui:latest"
}

variable "cds_image" {
  description = "ECR image for CDS App"
  type        = string
}

variable "redis_image" {
  description = "Redis container image"
  type        = string
  default     = "redis:7-alpine"
}


#############################################
# APPLICATION ENVIRONMENT VARIABLES
# (Everything that maps your Docker Compose envs)
#############################################

variable "java_opts" {
  description = "JVM options for CDS"
  type        = string
  default     = "-XX:+ExitOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/dump -XX:+UseStringDeduplication --enable-native-access=ALL-UNNAMED"
}

variable "app_args" {
  description = "Full Spring Boot args for CDS, auto-built using TF locals"
  type        = string
}

variable "kafka_bootstrap" {
  description = "Kafka bootstrap servers"
  type        = string
  default     = "kafka-bpp:9092"
}

variable "redis_url" {
  description = "Redis connection URL"
  type        = string
  default     = "redis://redis-bpp:6379"
}
