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

############################################
# SECURITY GROUP MODULE (create EKS SGs per VPC)
# it should return eks_nodes_sg_id (or similar)
############################################
module "eks_sg" {
  source = "../../security_group_eks"

  # Send ALL VPCs (module creates one SG per VPC)
  vpc_ids = module.vpc.vpc_ids

  # Send cluster mapping for each VPC
  cluster_names = var.cluster_names
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
# EKS module call (deploy into the selected VPC)
############################################
module "eks" {
  source = "../../eks"

  count = var.create_vpc

  # IMPORTANT: pass kubernetes provider to module
  # providers = {
  #   kubernetes = kubernetes.eks[count.index]
  # }

  cluster_name = var.cluster_names[count.index]

  subnet_ids = module.vpc.private_subnet_ids[count.index]

  worker_sg        = module.eks_sg.worker_sg_ids[count.index]
  control_plane_sg = module.eks_sg.control_plane_sg_ids[count.index]

  node_ami           = var.node_ami
  node_instance_type = var.node_instance_type
  key_name           = var.key_name

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  admin_role_arn = var.admin_role_arn
}





  # NEW ENTRY
 



