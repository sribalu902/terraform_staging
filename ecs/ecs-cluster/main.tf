############################################
# ECS CLUSTER MODULE
# Supports: Fargate + EC2 (Kafka host mode)
# NO SECRETS, NO TASKS — Infra only
############################################

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  tags = {
    Name = var.cluster_name
  }
}

############################################
# SECURITY GROUPS
############################################

# SG for Fargate Tasks (Redis, CDS, Onix, Kafka-UI)
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name_prefix}-ecs-tasks-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  # Outbound allowed (tasks talk to RDS, Kafka, Redis, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-ecs-tasks-sg"
  }
}

# SG for Kafka EC2 host
resource "aws_security_group" "ecs_ec2" {
  name        = "${var.name_prefix}-ecs-ec2-sg"
  description = "Security group for ECS EC2 Kafka hosts"
  vpc_id      = var.vpc_id

  ingress {
    description = "Kafka PLAINTEXT"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # internal only
  }

  ingress {
    description = "Kafka Controller"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH allowed only via Bastion SG
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = var.bastion_sg_ids
  }

  # Allow tasks and EC2 hosts to talk internally
  ingress {
    description     = "Internal ECS tasks"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-ecs-ec2-sg"
  }
}

############################################
# IAM ROLES
############################################

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.name_prefix}-ecs-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.name_prefix}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

############################################
# LAUNCH TEMPLATE FOR KAFKA EC2 HOST
############################################

resource "aws_launch_template" "ecs_kafka_lt" {
  name_prefix   = "${var.name_prefix}-ecs-kafka-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.ecs_ec2.id]
    associate_public_ip_address = false # PRIVATE subnet only
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
systemctl restart ecs
EOF
)

  tags = {
    Name = "${var.name_prefix}-ecs-kafka-lt"
  }
}

############################################
# AUTO SCALING GROUP (Kafka EC2 Instance)
############################################

resource "aws_autoscaling_group" "ecs_kafka_asg" {
  name                 = "${var.name_prefix}-ecs-kafka-asg"
  vpc_zone_identifier  = var.private_subnet_ids
  desired_capacity     = var.asg_desired
  min_size             = var.asg_min
  max_size             = var.asg_max
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.ecs_kafka_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-ecs-kafka-host"
    propagate_at_launch = true
  }
}

############################################
# CAPACITY PROVIDER
############################################

resource "aws_ecs_capacity_provider" "ecs_capacity" {
  name = "${var.name_prefix}-ec2-capacity"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_kafka_asg.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 75
    }

    managed_termination_protection = "ENABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "attach" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity.name
    weight            = 1
  }
}
