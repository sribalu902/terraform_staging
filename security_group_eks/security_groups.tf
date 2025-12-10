############################################
# EKS SECURITY GROUPS MODULE
# - One Cluster SG per VPC
# - One Worker (node) SG per VPC
############################################

# Worker SG (applied to EC2 nodes / managed node ENIs)
resource "aws_security_group" "eks_worker_sg" {
  count = var.create_vpc

  name        = "eks-worker-sg-${count.index}"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_ids[count.index]

  tags = merge(var.tags, {
    Name = "eks-worker-sg-${count.index}"
  })
}

# Cluster SG (this is a customer-created SG intended to be used
# for the EKS control-plane ENIs. Ensure you pass this SG into
# aws_eks_cluster.vpc_config.security_group_ids when creating the cluster
# so the control plane ENIs are created inside this SG.)
resource "aws_security_group" "eks_cluster_sg" {
  count = var.create_vpc

  name        = "eks-cluster-sg-${count.index}"
  description = "Security group for EKS control plane (cluster ENIs)"
  vpc_id      = var.vpc_ids[count.index]

  tags = merge(var.tags, {
    Name = "eks-cluster-sg-${count.index}"
  })
}

############################################
# RULES (Worker SG)
############################################

# 1) Worker <-> Worker (allow all between nodes) — required for kube-proxy,
# CNI, pod traffic that routes via host, etc.
resource "aws_security_group_rule" "worker_self" {
  count = var.create_vpc

  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_sg[count.index].id
  source_security_group_id = aws_security_group.eks_worker_sg[count.index].id
  description = "Worker to worker traffic"
}

# 2) Worker: allow VPC-internal ENI traffic (control-plane ENIs will use VPC CIDR)
# This ensures control-plane ENIs and other VPC components can reach nodes on ephemeral ports.
resource "aws_security_group_rule" "eks_enis_to_worker" {
  count = var.create_vpc

  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_worker_sg[count.index].id
  cidr_blocks       = [var.vpc_cidrs[count.index]]
 description = "Control plane ENIs to worker ephemeral ports"

}

# 3) Worker egress — allow nodes to reach the internet (for kubelet, pulls, SSM, etc.)
resource "aws_security_group_rule" "worker_egress_all" {
  count = var.create_vpc

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_worker_sg[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Worker egress (all)"
}

############################################
# RULES (Cluster SG)
# Notes:
#  - The control plane must be reachable (ingress) from worker nodes (kubelet auth)
#  - Control plane needs to reach worker nodes (for some bootstrap / nodeadm operations)
############################################

# 4) Allow workers (kubelet) -> API server (control plane) on TCP 443
resource "aws_security_group_rule" "worker_to_cluster_api" {
  count = var.create_vpc

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg[count.index].id
  source_security_group_id = aws_security_group.eks_worker_sg[count.index].id
  description = "Worker kubelet to control plane API 443"

}

# 5) (Optional / defensive) Allow workers -> control plane ephemeral ports (if required)
# Some control-plane interactions may expect ephemeral ranges; not always required,
# but harmless to include for managed node join flows.
resource "aws_security_group_rule" "worker_to_cluster_ephemeral" {
  count = var.create_vpc

  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg[count.index].id
  source_security_group_id = aws_security_group.eks_worker_sg[count.index].id
  description = "Worker to control plane ephemeral ports"

}
# 6) Allow control-plane SG -> worker on 443 (control plane initiating to node for some flows)
resource"aws_security_group_rule" "cluster_to_worker_api" {
  count = var.create_vpc

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg[count.index].id
  source_security_group_id = aws_security_group.eks_cluster_sg[count.index].id
  description = "Control plane to worker port 443"

}

# 7) Allow control plane -> worker kubelet port 10250 (some control-plane ops)
resource "aws_security_group_rule" "cluster_to_worker_kubelet" {
  count = var.create_vpc

  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_sg[count.index].id
  source_security_group_id = aws_security_group.eks_cluster_sg[count.index].id
 description = "Control plane to worker kubelet port 10250"

}
