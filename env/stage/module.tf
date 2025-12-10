############################################
# choose VPC by name or index:
# - If eks_vpc_name != "" and found in vpc_names => use that
# - Otherwise use eks_vpc_index (number)
############################################

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



##########################################
# VPC PEERING between the two VPCs created above
##########################################

# PEER ONLY IF 2 VPCs EXIST
module "peering" {
  count = var.create_vpc > 1 ? 1 : 0

  source = "../../peering"

  vpc_id_1 = module.vpc.vpc_ids[0]
  vpc_id_2 = module.vpc.vpc_ids[1]

  vpc_cidr_1 = module.vpc.vpc_cidrs[0]
  vpc_cidr_2 = module.vpc.vpc_cidrs[1]

  private_rt_vpc1 = module.vpc.private_route_table_ids[0]
  private_rt_vpc2 = module.vpc.private_route_table_ids[1]


  peering_name = "cds-bap-peering"
}




##########################################
# security group module for EC2 instances (create public SGs per VPC)
##########################################

module "security_group_ec2" {
  source = "../../security_group_ec2"

  vpc_ids        = module.vpc.vpc_ids   # multi-VPC support
  
}


#########################################
#creating ec2 public subnet
#########################################

module "ec2" {
  source = "../../ec2"

  ami_ids            = var.ami_ids
  instance_types     = var.instance_types
  ec2_instance_names = var.ec2_instance_names
  key_name           = var.key_name_ec2

  # Subnets per VPC → flatten only chosen VPCs
  subnet_ids = flatten([
    for vpc_index in var.ec2_vpc_index_list :
      module.vpc.public_subnet_ids[vpc_index]
  ])

  # SG list duplicated to match number of subnets in each VPC
  sg_ids = flatten([
    for vpc_index in var.ec2_vpc_index_list :
      [
        for s in module.vpc.public_subnet_ids[vpc_index] :
        module.security_group_ec2.sg_ids[vpc_index]
      ]
  ])
}


############################################
# SECURITY GROUP FOR EKS WORKER NODES (PER VPC)
############################################
module "security_group_eks" {
  source     = "../../security_group_eks"

  create_vpc = var.create_vpc
  vpc_ids    = module.vpc.vpc_ids
  tags       = var.tags
  vpc_cidrs = var.vpc_cidrs
}


############################################
# EKS MODULE – ONE CLUSTER PER VPC
############################################
resource "aws_iam_service_linked_role" "eks_nodegroup" {
  aws_service_name = "eks-nodegroup.amazonaws.com"
}


module "eks" {
  source = "../../eks"
  count  = var.create_vpc

  cluster_name = "${var.cluster_name_prefix}-${var.vpc_names[count.index]}"

  vpc_id = module.vpc.vpc_ids[count.index]
  subnet_ids = slice(module.vpc.private_subnet_ids[count.index], 0, 2)

  ############################################
  # CLUSTER + WORKER SGs (CRITICAL)
  ############################################
  cluster_security_group_ids = [
    module.security_group_eks.eks_cluster_sg_ids[count.index]
  ]

  worker_sg_id = module.security_group_eks.eks_worker_sg_ids[count.index]

  node_ssh_key_name = var.node_ssh_key_name

  node_groups     = var.node_groups
  node_group_tags = { Environment = var.environment }

  eks_version = var.eks_version
  tags        = var.tags
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


 



