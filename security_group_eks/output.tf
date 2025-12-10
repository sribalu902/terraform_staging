output "eks_worker_sg_ids" {
  value = aws_security_group.eks_worker_sg[*].id
}

output "eks_cluster_sg_ids" {
  value = aws_security_group.eks_cluster_sg[*].id
}

