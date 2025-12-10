############################################
# ECS SERVICE MODULE VARIABLES
############################################

variable "cluster_arn" {
  type        = string
  description = "ECS Cluster ARN"
}

variable "execution_role_arn" {
  type        = string
  description = "IAM role for ECS execution"
}

variable "task_role_arn" {
  type        = string
  description = "IAM task role"
}

variable "service_name" {
  type        = string
  description = "Name of ECS service"
}

variable "template_path" {
  type        = string
  description = "Path to task definition JSON template (*.tpl)"
}

variable "cpu" {
  type        = number
  description = "Task CPU"
}

variable "memory" {
  type        = number
  description = "Task memory"
}

variable "container_port" {
  type        = number
  description = "Container port to expose"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets to run tasks"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups for ECS task"
}

variable "assign_public_ip" {
  type        = bool
  default     = false
}

variable "environment" {
  type        = map(string)
  default     = {}
  description = "Dynamic env vars injected into task definition"
}

variable "enable_alb" {
  type        = bool
  default     = false
}

variable "alb_listener_arn" {
  type        = string
  default     = ""
}

variable "health_check_path" {
  type        = string
  default     = "/"
}
