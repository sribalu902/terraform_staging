################################################################################
# main.tf - Single-file demo infra (updated: Redpanda on ECS EC2 launch-type)
# - VPC, public subnets, IGW, route table
# - ECR repo
# - ECS cluster
#   - Fargate tasks (app, redis)
#   - EC2 capacity provider + ASG (for Redpanda)
# - Redpanda (Kafka-compatible) running on ECS EC2 host network
# - App task & Redis (Fargate)
# - PostgreSQL RDS (public) - enable PostGIS manually after creation
#
# WARNING: demo only. Public DB & open CIDRs used for simplicity.
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.23"
    }
  }
}


provider "aws" {
  region = "ap-south-1"
}

data "aws_caller_identity" "me" {}

################################################
# 1) NETWORK: VPC, subnets, IGW, route table
################################################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "demo-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "demo-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = { Name = "public-b" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

################################################
# 2) SECURITY GROUPS
################################################

# ECS tasks SG: allow App (80), Redis (6379), Kafka (9092) inbound for demo.
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg-demo"
  description = "SG for ECS tasks (app, redis, kafka)"
  vpc_id      = aws_vpc.main.id
  

  ingress {
    description = "App HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Redis (demo)"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka / Redpanda (demo)"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecs-sg-demo" }
}

# EC2 instances SG (for ECS container instances)
resource "aws_security_group" "ecs_instances_sg" {
  name        = "ecs-instances-sg"
  description = "SG for ECS EC2 instances (allow inbound for Kafka/Redis/App from internet for demo)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow Kafka"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Redis port"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow App port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ECS agent & Docker to reach ECR/STS/CloudWatch etc (outbound)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecs-instances-sg" }
}

# RDS security group: allow Postgres from ECS tasks & optionally dev IPs
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  vpc_id      = aws_vpc.main.id
  description = "SG for RDS Postgres - demo"

  ingress {
    description     = "Postgres from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id, aws_security_group.ecs_instances_sg.id]
  }

  # demo convenience
  ingress {
    description = "Dev laptop (demo)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-sg" }
}

################################################
# 3) ECR (container registry)
################################################
resource "aws_ecr_repository" "app_repo" {
  name = "app-ecr-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "app-ecr" }
}

################################################
# 4) ECS CLUSTER
################################################
resource "aws_ecs_cluster" "app_cluster" {
  name = "demo-ecs-cluster"
  tags = { Name = "demo-ecs-cluster" }
}

################################################
# 5) IAM roles for ECS task execution & EC2 instances
################################################

# Fargate/ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole-demo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# EC2 instance role for ECS container instances (so EC2 can run containers, pull ECR, send logs)
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole-demo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach necessary managed policies to instance role
resource "aws_iam_role_policy_attachment" "ecs_instance_managed_1" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "ecs_instance_managed_2" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "ecs_instance_managed_3" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile-demo"
  role = aws_iam_role.ecs_instance_role.name
}

################################################
# 6) ECS EC2 Capacity: Launch Template + ASG + Capacity Provider
#    (t3.large as requested)
################################################

# Hardcoded ECS optimized AMI to avoid SSM permissions issue
locals {
  ecs_ami_id = "ami-0298e0c0441cb5c66"
  # ECS optimized Amazon Linux 2 for ap-south-1
}

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-redpanda-"
  image_id      = local.ecs_ami_id
  instance_type = "t3.large"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50
      volume_type = "gp3"
    }
  }

  network_interfaces {
    security_groups             = [aws_security_group.ecs_instances_sg.id]
    associate_public_ip_address = true
  }

  # 🚀 FIX: Create Redpanda storage directory + permissions
  user_data = base64encode(<<EOF
#!/bin/bash

# ECS cluster
echo "ECS_CLUSTER=${aws_ecs_cluster.app_cluster.name}" >> /etc/ecs/ecs.config

# Redpanda hostPath directory
mkdir -p /var/lib/redpanda/data

# 🔥 Required by Redpanda v23: Must exist or startup FAILS
touch /var/lib/redpanda/data/.redpanda_data_dir

# Permissions
chmod -R 777 /var/lib/redpanda

EOF
)

lifecycle {
  create_before_destroy = true
}

}


resource "aws_autoscaling_group" "ecs_asg" {
  name             = "ecs-redpanda-asg"
  desired_capacity = 1
  max_size         = 2
  min_size         = 1
  protect_from_scale_in = true  # REQUIRED FIX
  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "ecs_capacity" {
  name = "redpanda-capacity"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1000
    }

    managed_termination_protection = "ENABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "attach_capacity" {
  cluster_name       = aws_ecs_cluster.app_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity.name
    weight            = 1
  }
}


################################################
# 7) CloudWatch log groups
################################################
resource "aws_cloudwatch_log_group" "redis_logs" {
  name              = "/ecs/redis"
  retention_in_days = 3
}
resource "aws_cloudwatch_log_group" "redpanda_logs" {
  name              = "/ecs/redpanda"
  retention_in_days = 3
}
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/app"
  retention_in_days = 3
}

################################################
# 8) ECS TASKS & SERVICES
#    - Redis (Fargate)
#    - Redpanda (EC2 launch type)
#    - App (Fargate) - commented but skeleton present
################################################

# ---------- Redis Task Definition (Fargate) ----------
resource "aws_ecs_task_definition" "redis_task" {
  family                   = "redis-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name = "redis"
      image = "redis:7"
      essential = true
      portMappings = [
        { containerPort = 6379, hostPort = 6379, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.redis_logs.name
          "awslogs-region" = "ap-south-1"
          "awslogs-stream-prefix" = "redis"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "redis_service" {
  name            = "redis-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.redis_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_cloudwatch_log_group.redis_logs]
}

# ---------- Redpanda Task Definition (EC2 host network) ----------
# Note: requires_compatibilities = ["EC2"] and network_mode = "host"
resource "aws_ecs_task_definition" "kafka_task" {
  family                   = "redpanda-ec2"
  requires_compatibilities = ["EC2"]
  network_mode             = "host"
  cpu                      = "1024"
  memory                   = "2048"

  # container definitions for host mode
  container_definitions = jsonencode([
    {
      name      = "redpanda"
      image     = "docker.redpanda.com/redpandadata/redpanda:v23.3.8"
      essential = true

      # host networking -> ports are on host; ensure instance SG allows them
      portMappings = [
        { containerPort = 9092, hostPort = 9092, protocol = "tcp" }
      ]

      # mount to host path (ECS EC2 will map host path)
      mountPoints = [
        {
          containerPath = "/var/lib/redpanda/data"
          sourceVolume  = "rpd-data"
          readOnly      = false
        }
      ]

      ccommand = [
  "/bin/bash",
  "-c",
  <<EOF
IP=$(curl -s $ECS_CONTAINER_METADATA_URI_V4 | jq -r '.Networks[0].IPv4Addresses[0]');
/usr/bin/rpk redpanda start \
  --overprovisioned \
  --smp 1 \
  --memory 1G \
  --reserve-memory 0M \
  --node-id 0 \
  --check=false \
  --kafka-addr PLAINTEXT://0.0.0.0:9092 \
  --advertise-kafka-addr PLAINTEXT://$IP:9092;
EOF
]


      environment = [
        { name = "REDPANDA_AUTO_CREATE_TOPICS", value = "true" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.redpanda_logs.name
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "redpanda"
        }
      }
    }
  ])

  # volumes - sourceVolume will map to host path on EC2 instances
  volume {
    name = "rpd-data"
    # Each EC2 instance will store data under /var/lib/redpanda/data (create by userdata or AMI)
    host_path = "/var/lib/redpanda/data"
  }
}

# Redpanda ECS service (use capacity provider -> EC2 launch type)
resource "aws_ecs_service" "kafka_service" {
  name            = "redpanda-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.kafka_task.arn
  desired_count   = 1
  force_new_deployment = true    # <-- REQUIRED FIX

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity.name
    weight            = 1
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_cloudwatch_log_group.redpanda_logs]
}

# ---------- App Task Definition (Fargate) ----------
# Skeleton - keep commented or enable and adjust repository URL for devs
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name = "app"
      image = "${aws_ecr_repository.app_repo.repository_url}:latest"
      essential = true
      portMappings = [
        { containerPort = 80, hostPort = 80, protocol = "tcp" }
      ]
      environment = [
        { name = "DATABASE_HOST", value = aws_db_instance.postgres.address },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_USER", value = "postgresadmin" },
        { name = "DATABASE_PASSWORD", value = "postgrespassword" },
        { name = "REDIS_HOST", value = "redis-service" },   # service name (internal)
        { name = "REDIS_PORT", value = "6379" },
        { name = "KAFKA_BROKER", value = "PLAINTEXT://<replace-with-ec2-host-private-ip>:9092" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.app_logs.name
          "awslogs-region" = "ap-south-1"
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_cloudwatch_log_group.app_logs]
}

################################################
# 9) POSTGRES RDS (public) - demo
#    IMPORTANT: enable PostGIS manually after DB is up
################################################

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "demo-postgres-subnet-group"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  tags = { Name = "demo-postgres-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "demo-postgres"
  engine                 = "postgres"
  engine_version         = "17.7"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "postgresadmin"
  password               = "postgrespassword"
  publicly_accessible    = true
  skip_final_snapshot    = true

  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = { Name = "demo-postgres" }
}

################################################
# 10) OUTPUTS - quick references for devs
################################################

output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "Public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "ecr_repo_url" {
  description = "ECR repository URL - push your app image here: <repo>:latest"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app_cluster.name
}

output "redis_service_name" {
  description = "Redis service name"
  value       = aws_ecs_service.redis_service.name
}

output "kafka_service_name" {
  description = "Redpanda service name (EC2 launch type)"
  value       = aws_ecs_service.kafka_service.name
}

output "postgres_endpoint" {
  description = "Postgres endpoint - use psql or your app to connect"
  value       = aws_db_instance.postgres.address
}

################################################################################
# NOTES & ACTIONS AFTER APPLY
#
# 1) After terraform apply:
#    - Wait for EC2 instance(s) to be provisioned in the ASG. They register to the ECS cluster
#      (check EC2 console -> instances -> user-data and /var/lib/ecs/ecs.config).
#    - ECS EC2 instances will create the host path /var/lib/redpanda/data if needed (you may
#      create this directory in user_data if AMI doesn't create it).
#
# 2) We use host networking for Redpanda. To get the Redpanda broker address for app config:
#      - In EC2 console, find the ECS instance running the redpanda task -> note its Private IP
#      - Use PLAINTEXT://<instance-private-ip>:9092 in your app environment (or set up a discovery script).
#
# 3) If you want terraform to write the instance private IP to a parameter or SSM for the app,
#    we can add a small script or use the AWS CLI in userdata to push the IP after boot.
#
# 4) Redpanda requires directories with correct permissions on host. If Redpanda fails,
#    SSH into the EC2 instance (enable SSH in SG) or use SSM to check /var/lib/redpanda/data ownership.
#
# 5) For production, prefer:
#      - dedicated EBS for redpanda data + proper RAID or volumes
#      - use EFS only if appropriate
#      - use MSK or a managed Kafka for production
#
################################################################################
