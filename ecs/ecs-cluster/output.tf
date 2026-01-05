############################################
# ECS CLUSTER
############################################
output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

############################################
# SECURITY GROUPS
############################################
output "ecs_tasks_sg_id" {
  description = "Security group ID for ECS Fargate tasks"
  value       = aws_security_group.ecs_tasks.id
}

# Primary name (used internally)
output "ecs_kafka_ec2_sg_id" {
  description = "Security group ID for Kafka EC2 hosts"
  value       = aws_security_group.ecs_ec2.id
}

# Alias name (EXPECTED by env/dev code)
output "kafka_ec2_sg_id" {
  description = "Alias output for Kafka EC2 SG"
  value       = aws_security_group.ecs_ec2.id
}

############################################
# IAM ROLES FOR ECS TASKS
############################################
output "execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "task_role_arn" {
  description = "IAM role ARN for ECS task"
  value       = aws_iam_role.ecs_task_role.arn
}

############################################
# EC2 CAPACITY PROVIDER
############################################
output "capacity_provider_name" {
  description = "ECS EC2 capacity provider name"
  value       = aws_ecs_capacity_provider.ecs_capacity.name
}

output "kafka_asg_name" {
  description = "Auto Scaling Group name for Kafka EC2"
  value       = aws_autoscaling_group.ecs_kafka_asg.name
}
