###########################################
# EKS OUTPUTS
###########################################

output "cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "node_group_names" {
  value = keys(aws_eks_node_group.node_groups)
}



