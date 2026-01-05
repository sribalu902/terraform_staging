#######################################################
# EKS ROOT MODULE (NO LAUNCH TEMPLATE)
#######################################################

############### 1. IAM ROLE FOR CLUSTER ###############
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}


############### 2. CREATE EKS CLUSTER ###############
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false

    # cluster SG must be passed from root module
    security_group_ids = var.cluster_security_group_ids
  }

  tags = merge(var.tags, { Name = var.cluster_name })
}


############### 3. NODE IAM ROLE ###############
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_CNI" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ECR" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_SSM" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


############### 4. MANAGED NODE GROUPS ###############
locals {
  node_group_map = { for ng in var.node_groups : ng.name => ng }
}

resource "aws_eks_node_group" "node_groups" {
  for_each = local.node_group_map

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids     = var.subnet_ids
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size
  ami_type       = lookup(each.value, "ami_type", var.default_ami_type)
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  update_config {
    max_unavailable = lookup(each.value, "max_unavailable", 1)
  }

  labels = lookup(each.value, "labels", {})

  ###############################################
  # Remote access allowed (ONLY when no LT used)
  ###############################################
  dynamic "remote_access" {
    for_each = var.node_ssh_key_name != "" ? [1] : []
    content {
      ec2_ssh_key               = var.node_ssh_key_name
      source_security_group_ids = [var.worker_sg_id]
    }
  }

  tags = merge(var.node_group_tags, {
    Name = "${var.cluster_name}-${each.key}"
  })
}
