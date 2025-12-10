###########################################
# EKS OUTPUTS
###########################################

output "cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "cluster_arn" {
  value = aws_eks_cluster.cluster.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "cluster_security_group_id" {
  value = var.cluster_security_group_ids[0]
}

