output "eks_worker_sg_ids" {
  value = aws_security_group.eks_worker_sg[*].id
}
