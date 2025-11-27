#######################################################
# EKS cluster (production-friendly) + managed nodegroups
# - Targeting EKS 1.29 (compatible with provider v6.x)
# - Uses managed node groups (dynamic)
# - Creates required service-linked role for nodegroups (permanent fix)
# - Conditional remote_access (only if key provided)
# - Clear inline comments explaining what/why for production
#######################################################

############################
# 2) Cluster IAM role (control-plane)
############################
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach managed policies required by EKS control plane
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

############################
# 3) EKS Cluster
# For EKS 1.29+ we don't need to add Auto Mode disabling flags
# Keep cluster config minimal and production-friendly (private endpoint by default)
############################
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # Node traffic stays in private subnets (recommended for prod)
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  # Ensure the cluster has a friendly set of tags
  tags = merge(var.tags, { Name = var.cluster_name })
}

############################
# 4) Node IAM role and policies (for managed node groups)
############################
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

  depends_on = [aws_iam_role.eks_node_role]
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSCNIPolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "node_ECR_ReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "node_SSM" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

############################
# 5) Dynamic managed node groups
# - Create one aws_eks_node_group per object in var.node_groups
# - remote_access is created only when var.node_ssh_key_name is not null/empty
############################
locals {
  node_group_map = { for ng in var.node_groups : ng.name => ng }
}

resource "aws_eks_node_group" "node_groups" {
  for_each = local.node_group_map

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_node_role.arn
  depends_on = [
  aws_eks_cluster.cluster,
  aws_iam_role.eks_node_role,

  aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
  aws_iam_role_policy_attachment.node_AmazonEKSCNIPolicy,
  aws_iam_role_policy_attachment.node_ECR_ReadOnly,
  aws_iam_role_policy_attachment.node_SSM
]



  # place nodes into the private subnets provided by the VPC module
  subnet_ids     = var.subnet_ids
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  labels = lookup(each.value, "labels", {})

  update_config {
    # how many nodes can be unavailable during upgrades (1 is safe default)
    max_unavailable = lookup(each.value, "max_unavailable", 1)
  }

  # Remote access: create this block ONLY if a key name is provided in tfvars
  dynamic "remote_access" {
    for_each = var.node_ssh_key_name != null && var.node_ssh_key_name != "" ? [1] : []
    content {
      ec2_ssh_key               = var.node_ssh_key_name
      source_security_group_ids = [var.worker_sg_id]
    }
  }

  tags = merge(var.node_group_tags, {
    Name               = "${var.cluster_name}-${each.key}"
    "eks:cluster-name" = var.cluster_name
  })

}
############################
# 6) Expose useful outputs (keep outputs in a separate outputs.tf if you prefer)
###########################
