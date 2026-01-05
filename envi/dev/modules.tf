############################################
# VPC module (assumed to already exist)
############################################
module "vpc" {
  source = "../../vpc"

  create_vpc              = var.create_vpc
  vpc_names               = var.vpc_names
  vpc_cidrs               = var.vpc_cidrs
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  public_subnet_azs       = var.public_subnet_azs
  private_subnet_azs      = var.private_subnet_azs
  public_subnets_per_vpc  = var.public_subnets_per_vpc
  private_subnets_per_vpc = var.private_subnets_per_vpc
  cluster_names           = var.cluster_names
}

module "rds" {
  source = "../../rds"

  vpc_ids            = module.vpc.vpc_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  vpc_indexes        = var.vpc_indexes
  identifier_prefix  = var.identifier_prefix

  db_name            = var.db_name
  username           = var.username
  password           = var.password

  engine_version     = var.engine_version
  instance_class     = var.instance_class
  allocated_storage  = var.allocated_storage
  publicly_accessible = var.publicly_accessible
  skip_final_snapshot = var.skip_final_snapshot

  allowed_sg_ids = [
    [
      #  module.ecs.ecs_sg_id,
      #  module.kafka.kafka_sg_id,
      module.bastion.sg_ids[0]
    ]
  ]
}

##########################################
# Bastion Module
##########################################

  module "bastion" {
  source = "../../bastion"

  vpc_ids           = module.vpc.vpc_ids
  public_subnet_ids = module.vpc.public_subnet_ids

  ami_id   = var.bastion_ami_id
  key_name = var.bastion_key_name
  ssh_cidr = var.ssh_cidr

 
}


############################################
# ECS CLUSTER MODULE
############################################

module "ecs_cluster" {
  source = "../../ecs/ecs-cluster"

  cluster_name = var.cluster_name
  name_prefix  = var.name_prefix

  ########################################
  # VPC & SUBNETS
  ########################################
  vpc_id             = module.vpc.vpc_ids[0]
  vpc_cidr           = module.vpc.vpc_cidrs[0]
  private_subnet_ids = module.vpc.private_subnet_ids[0]
  public_subnet_ids  = module.vpc.public_subnet_ids[0]

  ########################################
  # SECURITY GROUPS
  ########################################
  # Bastion SG required because Kafka EC2 must allow SSH from bastion
  bastion_sg_ids = [
    module.bastion.sg_ids[0]
  ]

  ########################################
  # EC2 HOST (Kafka)
  ########################################
  # ami_id       = var.kafka_ami_id
  instance_type = var.kafka_instance_type
  key_name      = var.kafka_key_name

  asg_desired = var.kafka_asg_desired
  asg_min     = var.kafka_asg_min
  asg_max     = var.kafka_asg_max
}


# #############################################
# # REDIS SERVICE — FARGATE
# ############################################
# module "redis" {
#   source = "../../ecs/ecs-service"

#   service_name  = "redis-bpp"
#   cluster_arn   = module.ecs_cluster.cluster_arn

#   cpu            = var.redis_cpu
#   memory         = var.redis_memory
#   container_port = var.redis_port

#   subnet_ids         = module.vpc.private_subnet_ids[0]
#   security_group_ids = [module.ecs_cluster.ecs_tasks_sg_id]
#   assign_public_ip   = false

#   execution_role_arn = module.ecs_cluster.execution_role_arn
#   task_role_arn      = module.ecs_cluster.task_role_arn

#   template_path = "${path.module}/../../ecs/ecs-taskdef/redis.json.tpl"
# }



# ############################################
# # KAFKA SERVICE — EC2 Host Mode (from JSON)
# ############################################
# module "kafka" {
#   source = "../../ecs/ecs-ec2-service"

#   service_name = "kafka-bpp"
#   cluster_arn  = module.ecs_cluster.cluster_arn

#   cpu    = var.kafka_cpu
#   memory = var.kafka_memory

#   execution_role_arn = module.ecs_cluster.execution_role_arn
#   task_role_arn      = module.ecs_cluster.task_role_arn

#   capacity_provider_name = module.ecs_cluster.capacity_provider_name

#   template_path = "${path.module}/../../ecs/ecs-taskdef/kafka.json.tpl"
# }


# ############################################
# # KAFKA UI SERVICE — Fargate
# ############################################
# module "kafka_ui" {
#   source = "../../ecs/ecs-service"

#   # --- Service identity ---
#   service_name  = "kafka-ui-bpp"
#   cluster_arn   = module.ecs_cluster.cluster_arn

#   # --- Task Sizing (goes into JSON: ${CPU}, ${MEMORY}) ---
#   cpu            = var.kafka_ui_cpu
#   memory         = var.kafka_ui_memory

#   # Kafka UI listens on port 8080 internally
#   container_port = var.kafka_ui_port

#   # --- Networking ---
#   subnet_ids         = module.vpc.private_subnet_ids[0]
#   security_group_ids = [module.ecs_cluster.ecs_tasks_sg_id]
#   assign_public_ip   = false

#   # --- IAM roles from ECS cluster ---
#   execution_role_arn = module.ecs_cluster.execution_role_arn
#   task_role_arn      = module.ecs_cluster.task_role_arn

#   # --- JSON Template Path ---
#   template_path = "${path.module}/../../ecs/task-defs/kafka-ui.json"
# }


# ############################################
# # ONIX PLUGIN SERVICE — Fargate
# ############################################
# module "onix" {
#   source = "../../ecs/ecs-service"

#   # --- Service Identity ---
#   service_name  = "onix-bpp-plugin"
#   cluster_arn   = module.ecs_cluster.cluster_arn

#   # --- Task Resources (to JSON: ${CPU}, ${MEMORY}) ---
#   cpu            = var.onix_cpu
#   memory         = var.onix_memory

#   # Onix always listens on port 8002
#   container_port = var.onix_port

#   # --- Networking ---
#   subnet_ids         = module.vpc.private_subnet_ids[0]
#   security_group_ids = [module.ecs_cluster.ecs_tasks_sg_id]
#   assign_public_ip   = false

#   # --- IAM roles from ECS cluster ---
#   execution_role_arn = module.ecs_cluster.execution_role_arn
#   task_role_arn      = module.ecs_cluster.task_role_arn

#   # --- JSON Template ---
#   template_path = "${path.module}/../../ecs/task-defs/onix.json"
# }

# ############################################
# # CDS SERVICE — Fargate
# ############################################
# module "cds" {
#   source = "../../ecs/ecs-service"

#   service_name  = "cds-app"
#   cluster_arn   = module.ecs_cluster.cluster_arn

#   cpu           = var.cds_cpu
#   memory        = var.cds_memory
#   container_port = 8080

#   subnet_ids         = module.vpc.private_subnet_ids[0]
#   security_group_ids = [module.ecs_cluster.ecs_tasks_sg_id]
#   assign_public_ip   = false

#   execution_role_arn = module.ecs_cluster.execution_role_arn
#   task_role_arn      = module.ecs_cluster.task_role_arn

#   template_path = "${path.module}/../../ecs/task-defs/cds.json"

#   # NEW
# #   cds_java_opts = var.cds_java_opts
# #   cds_app_args  = var.cds_app_args
# #   cds_image     = var.cds_image
# }
