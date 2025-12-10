// main.tf
locals {
  name_prefix = "${var.project}-${var.environment}"
  log_group   = "/ecs/${local.name_prefix}"
}

# Basic VPC + subnets (you already have but include here)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

# Public subnets (for Bastion, Kafka EC2s, NAT)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = var.az_a
  map_public_ip_on_launch = true
  tags = { Name = "${local.name_prefix}-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone       = var.az_b
  map_public_ip_on_launch = true
  tags = { Name = "${local.name_prefix}-public-b" }
}

# Private subnets (for ECS Fargate & RDS)
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 3)
  availability_zone       = var.az_a
  map_public_ip_on_launch = false
  tags = { Name = "${local.name_prefix}-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 4)
  availability_zone       = var.az_b
  map_public_ip_on_launch = false
  tags = { Name = "${local.name_prefix}-private-b" }
}

# NAT & route tables (so private subnets can reach ECR/internet)
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags = { Name = "${local.name_prefix}-nat" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0"; gateway_id = aws_internet_gateway.igw.id }
  tags = { Name = "${local.name_prefix}-public-rt" }
}
# ----------------------------------------------------------
# PUBLIC ROUTE TABLE ASSOCIATIONS
# ----------------------------------------------------------

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ----------------------------------------------------------
# PRIVATE ROUTE TABLE (Uses NAT Gateway)
# ----------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt"
  }
}

# ----------------------------------------------------------
# PRIVATE ROUTE TABLE ASSOCIATIONS
# ----------------------------------------------------------

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# SECURITY GROUPS
# ALB SG
resource "aws_security_group" "alb_sg" {
  name   = "${local.name_prefix}-alb-sg"
  vpc_id = aws_vpc.main.id
  description = "ALB security group - public"
  ingress {
    from_port   = var.onix_container_port
    to_port     = var.onix_container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Onix public"
  }
  ingress {
    from_port   = var.kafka_ui_container_port
    to_port     = var.kafka_ui_container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kafka UI public"
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${local.name_prefix}-alb-sg" }
}

# ECS tasks SG (private)
resource "aws_security_group" "ecs_tasks_sg" {
  name   = "${local.name_prefix}-ecs-sg"
  vpc_id = aws_vpc.main.id
  description = "ECS tasks SG - private"
  # allow inbound from ALB for onix & kafka-ui (target groups will use this)
  ingress {
    from_port       = var.onix_container_port
    to_port         = var.onix_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow ALB -> Onix"
  }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow ALB -> Kafka UI container (8080)"
  }
  # allow internal communication between ecs tasks (cds -> redis, cds -> kafka)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow internal ECS traffic"
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${local.name_prefix}-ecs-sg" }
}

# Kafka EC2 SG (public - allow 9092/9093 and ssh from bastion or your IP)
resource "aws_security_group" "kafka_ec2_sg" {
  name   = "${local.name_prefix}-kafka-ec2-sg"
  vpc_id = aws_vpc.main.id
  description = "Kafka EC2 nodes public for dev debugging"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # consider restricting to your office/dev IPs
    description = "SSH (dev)"
  }
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kafka PLAINTEXT (dev)"
  }
  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kafka controller (dev)"
  }
  # allow ECS tasks to talk to kafka on 9092/9093
  ingress {
    from_port       = 9092
    to_port         = 9093
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    description     = "Allow ECS tasks -> Kafka"
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${local.name_prefix}-kafka-ec2-sg" }
}

# RDS SG - allow only ECS tasks and kafka EC2 (if needed)
resource "aws_security_group" "rds_sg" {
  name   = "${local.name_prefix}-rds-sg"
  vpc_id = aws_vpc.main.id
  description = "RDS SG - allow only ECS tasks"
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id, aws_security_group.kafka_ec2_sg.id]
    description = "Postgres from ECS and Kafka EC2"
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${local.name_prefix}-rds-sg" }
}

# Bastion SG (public)
resource "aws_security_group" "bastion_sg" {
  name   = "${local.name_prefix}-bastion-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # restrict in prod
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${local.name_prefix}-bastion-sg" }
}

####################
# CloudWatch log groups
####################
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = local.log_group
  retention_in_days = 7
}

####################
# IAM Roles for ECS tasks
####################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name_prefix}-ecs-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name_prefix}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

####################
# ECR repos (placeholders)
####################
resource "aws_ecr_repository" "onix_repo" {
  name = "${local.name_prefix}-onix"
}
resource "aws_ecr_repository" "cds_repo" {
  name = "${local.name_prefix}-cds"
}
resource "aws_ecr_repository" "kafka_ui_repo" {
  name = "${local.name_prefix}-kafka-ui"
}

####################
# ECS cluster
####################
resource "aws_ecs_cluster" "cluster" {
  name = "${local.name_prefix}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = { Name = "${local.name_prefix}-cluster" }
}

####################
# Launch template + ASG for Kafka EC2 instances (host mode)
####################
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_launch_template" "kafka_lt" {
  name_prefix   = "${local.name_prefix}-kafka-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.kafka_instance_type
  key_name      = var.key_name

  iam_instance_profile { name = aws_iam_instance_profile.kafka_instance_profile.name }

  network_interfaces {
    security_groups             = [aws_security_group.kafka_ec2_sg.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(<<EOF
#!/bin/bash
# install ECS agent & Docker & jq
apt-get update -y
apt-get install -y awscli jq docker.io
systemctl enable docker
systemctl start docker

# install ecs agent (amazon ecs-init not available on ubuntu by default) - use amazon-ecs-init on Amazon Linux
# Register as ECS container instance by writing ECS_CLUSTER
echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" > /etc/ecs/ecs.config || true
# simple: start ecs agent via docker (this is a dev-friendly approach)
docker run -d --name ecs-agent --restart always -e AWS_DEFAULT_REGION=${var.aws_region} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  amazon/amazon-ecs-agent:latest
EOF
  )

  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "kafka_asg" {
  name                      = "${local.name_prefix}-kafka-asg"
  desired_capacity          = var.kafka_desired_count
  max_size                  = var.kafka_desired_count
  min_size                  = var.kafka_desired_count
  launch_template {
    id      = aws_launch_template.kafka_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  force_delete = true
}

resource "aws_iam_role" "kafka_instance_role" {
  name = "${local.name_prefix}-kafka-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "kafka_instance_managed" {
  role       = aws_iam_role.kafka_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "kafka_instance_profile" {
  name = "${local.name_prefix}-kafka-instance-profile"
  role = aws_iam_role.kafka_instance_role.name
}

# Capacity provider to attach ASG to ECS cluster
resource "aws_ecs_capacity_provider" "kafka_capacity" {
  name = "${local.name_prefix}-capacity"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.kafka_asg.arn
    managed_scaling {
      status                    = "DISABLED"
    }
    managed_termination_protection = "ENABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "attach_capacity" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [aws_ecs_capacity_provider.kafka_capacity.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.kafka_capacity.name
    weight            = 1
  }
}

####################
# RDS Postgres (private)
####################
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags = { Name = "${local.name_prefix}-db-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${local.name_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "17.7"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  tags = { Name = "${local.name_prefix}-postgres" }
}

####################
# ALB (public) with listeners 8002 and 8081 if create_alb = true
####################
resource "aws_lb" "alb" {
  count = var.create_alb ? 1 : 0
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  tags = { Name = "${local.name_prefix}-alb" }
}

# Target groups for Onix and Kafka UI
resource "aws_lb_target_group" "onix_tg" {
  count    = var.create_alb ? 1 : 0
  name     = "${local.name_prefix}-onix-tg"
  port     = var.onix_container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/actuator/health"; matcher = "200-399"; interval = 10; timeout = 5; healthy_threshold = 2; unhealthy_threshold = 3 }
}

resource "aws_lb_target_group" "kafka_ui_tg" {
  count    = var.create_alb ? 1 : 0
  name     = "${local.name_prefix}-kafka-ui-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/"; matcher = "200-399"; interval = 10; timeout = 5; healthy_threshold = 2; unhealthy_threshold = 3 }
}

# Listeners
resource "aws_lb_listener" "onix_listener" {
  count = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.alb[0].arn
  port              = var.onix_container_port
  protocol          = "HTTP"
  default_action { type = "forward"; target_group_arn = aws_lb_target_group.onix_tg[0].arn }
}

resource "aws_lb_listener" "kafka_ui_listener" {
  count = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.alb[0].arn
  port              = var.kafka_ui_container_port
  protocol          = "HTTP"
  default_action { type = "forward"; target_group_arn = aws_lb_target_group.kafka_ui_tg[0].arn }
}

####################
# ECS Task Definitions via templatefile()
####################
# Build common vars used in templatefile
locals {
  kafka_bootstrap = "kafka-bpp:9092"         # service name used by tasks; we'll also expose kafka via cluster host for debugging
  spring_datasource_url = "jdbc:postgresql://${aws_db_instance.postgres.address}:5432/${var.db_name}"
  redis_url = "redis://redis-bpp:${var.redis_container_port}"
  java_opts = "-XX:+ExitOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/dump -XX:+UseStringDeduplication --enable-native-access=ALL-UNNAMED"
  app_args = join(" ", [
    "--spring.threads.virtual.enabled=true",
    "--spring.profiles.active=kafka,postgres,redis,dev",
    "--spring.kafka.consumer.bootstrap-servers=${local.kafka_bootstrap}",
    "--spring.kafka.producer.bootstrap-servers=${local.kafka_bootstrap}",
    "--spring.datasource.url=${local.spring_datasource_url}",
    "--spring.datasource.username=${var.db_username}",
    "--spring.datasource.password=${var.db_password}",
    "--spring.data.redis.url=${local.redis_url}"
  ])
}

data "templatefile" "onix_task_json" {
  template = file("${path.module}/ecs/onix_task.json")
  vars = {
    onix_cpu = var.onix_cpu
    onix_memory = var.onix_memory
    onix_image = var.onix_image
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn
    onix_container_port = var.onix_container_port
    kafka_bootstrap = local.kafka_bootstrap
    spring_datasource_url = local.spring_datasource_url
    db_username = var.db_username
    db_password = var.db_password
    redis_url = local.redis_url
    log_group = local.log_group
    aws_region = var.aws_region
  }
}

resource "aws_ecs_task_definition" "onix" {
  family                   = "onix-plugin-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.onix_cpu)
  memory                   = tostring(var.onix_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions    = data.templatefile.onix_task_json.rendered
}

data "templatefile" "kafka_ui_task_json" {
  template = file("${path.module}/ecs/kafka_ui_task.json")
  vars = {
    kafka_ui_cpu = var.kafka_ui_cpu
    kafka_ui_memory = var.kafka_ui_memory
    kafka_ui_image = var.kafka_ui_image
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn
    kafka_bootstrap = local.kafka_bootstrap
    log_group = local.log_group
    aws_region = var.aws_region
  }
}

resource "aws_ecs_task_definition" "kafka_ui" {
  family                   = "kafka-ui-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.kafka_ui_cpu)
  memory                   = tostring(var.kafka_ui_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions    = data.templatefile.kafka_ui_task_json.rendered
}

data "templatefile" "cds_task_json" {
  template = file("${path.module}/ecs/cds_task.json")
  vars = {
    cds_cpu = var.cds_cpu
    cds_memory = var.cds_memory
    cds_image = var.cds_image
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn
    cds_container_port = var.cds_container_port
    java_opts = local.java_opts
    app_args = local.app_args
    spring_datasource_url = local.spring_datasource_url
    db_username = var.db_username
    db_password = var.db_password
    kafka_bootstrap = local.kafka_bootstrap
    redis_url = local.redis_url
    log_group = local.log_group
    aws_region = var.aws_region
  }
}

resource "aws_ecs_task_definition" "cds" {
  family                   = "cds-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cds_cpu)
  memory                   = tostring(var.cds_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions    = data.templatefile.cds_task_json.rendered
}

data "templatefile" "redis_task_json" {
  template = file("${path.module}/ecs/redis_task.json")
  vars = {
    redis_cpu = var.redis_cpu
    redis_memory = var.redis_memory
    redis_image = var.redis_image
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn
    redis_container_port = var.redis_container_port
    log_group = local.log_group
    aws_region = var.aws_region
  }
}

resource "aws_ecs_task_definition" "redis" {
  family                   = "redis-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.redis_cpu)
  memory                   = tostring(var.redis_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions    = data.templatefile.redis_task_json.rendered
}

####################
# ECS Services
####################
# Redis
resource "aws_ecs_service" "redis" {
  name            = "redis-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  depends_on = [aws_cloudwatch_log_group.ecs_logs]
}

# CDS App (internal only)
resource "aws_ecs_service" "cds" {
  name            = "cds-app-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.cds.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  depends_on = [aws_ecs_service.redis, aws_db_instance.postgres]
}

# Kafka UI (Fargate) - private, fronted by ALB target group (ip targets)
resource "aws_ecs_service" "kafka_ui" {
  name            = "kafka-ui-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.kafka_ui.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.create_alb ? aws_lb_target_group.kafka_ui_tg[0].arn : ""
    container_name   = "kafka-ui"
    container_port   = 8080
  }

  depends_on = [aws_ecs_service.redis]
}

# Onix plugin (Fargate) - private, fronted by ALB
resource "aws_ecs_service" "onix" {
  name            = "onix-plugin-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.onix.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.create_alb ? aws_lb_target_group.onix_tg[0].arn : ""
    container_name   = "onix-plugin"
    container_port   = var.onix_container_port
  }

  depends_on = [aws_ecs_service.redis, aws_ecs_service.kafka_ui, aws_db_instance.postgres]
}

####################
# ALB target registration happens automatically via aws ecs service load_balancer config above (ip mode)
####################

####################
# Bastion host
####################
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.bastion_instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = { Name = "${local.name_prefix}-bastion" }
}

####################
# Outputs
####################
output "vpc_id" { value = aws_vpc.main.id }
output "private_subnets" { value = [aws_subnet.private_a.id, aws_subnet.private_b.id] }
output "public_subnets" { value = [aws_subnet.public_a.id, aws_subnet.public_b.id] }
output "ecs_cluster_name" { value = aws_ecs_cluster.cluster.name }
output "postgres_endpoint" { value = aws_db_instance.postgres.address }
output "onix_service_name" { value = aws_ecs_service.onix.name }
output "kafka_ui_service_name" { value = aws_ecs_service.kafka_ui.name }
output "redis_service_name" { value = aws_ecs_service.redis.name }
output "cds_service_name" { value = aws_ecs_service.cds.name }
output "alb_dns" { value = var.create_alb ? aws_lb.alb[0].dns_name : "" }
