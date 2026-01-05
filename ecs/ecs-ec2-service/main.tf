############################################
# REGION
############################################
data "aws_region" "current" {}

############################################
# CLOUDWATCH LOG GROUP (REQUIRED)
############################################
resource "aws_cloudwatch_log_group" "kafka" {
  name              = "/ecs/kafka"
  retention_in_days = 7
}

############################################
# RENDER TASK DEFINITION
############################################
locals {
  rendered_task = templatefile(
    var.template_path,
    {
      AWS_REGION = data.aws_region.current.id
    }
  )
}

############################################
# ECS TASK DEFINITION (EC2)
############################################
resource "aws_ecs_task_definition" "kafka" {
  family                   = "kafka"
  network_mode             = "host"
  requires_compatibilities = ["EC2"]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = local.rendered_task

  volume {
    name = "kafka-data"
    host_path = "/var/lib/kafka/data"
  }

  depends_on = [
    aws_cloudwatch_log_group.kafka
  ]
}

############################################
# ECS SERVICE (EC2)
############################################
resource "aws_ecs_service" "kafka" {
  name            = "kafka"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.kafka.arn
  desired_count   = 1
  launch_type     = "EC2"

  enable_execute_command = true

  depends_on = [
    aws_ecs_task_definition.kafka
  ]
}
