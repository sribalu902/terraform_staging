data "aws_region" "current" {}

############################################
# RENDER TASK DEFINITION
############################################

locals {
  rendered_task = templatefile(
    var.template_path,
    merge(
      var.environment,
      {
        CPU        = var.cpu
        MEMORY     = var.memory
        AWS_REGION = data.aws_region.current.name
      }
    )
  )
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  container_definitions    = local.rendered_task
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu              = var.cpu
  memory           = var.memory
  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn
}

############################################
# ECS SERVICE
############################################

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[0].arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  depends_on = [
    aws_ecs_task_definition.this
  ]
}

############################################
# OPTIONAL ALB TARGET GROUP + LISTENER RULE
############################################

resource "aws_lb_target_group" "this" {
  count = var.enable_alb ? 1 : 0

  name        = "${var.service_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_subnet.selected.vpc_id

  health_check {
    path = var.health_check_path
  }
}

resource "aws_lb_listener_rule" "this" {
  count = var.enable_alb ? 1 : 0

  listener_arn = var.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

data "aws_subnet" "selected" {
  id = var.subnet_ids[0]
}
