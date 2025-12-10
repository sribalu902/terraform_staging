output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "service_arn" {
  value = aws_ecs_service.this.arn
}

output "target_group_arn" {
  value = var.enable_alb ? aws_lb_target_group.this[0].arn : null
}
