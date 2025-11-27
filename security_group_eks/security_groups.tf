resource "aws_security_group" "eks_worker_sg" {
  count = var.create_vpc   # one SG per VPC

  name        = "eks-worker-sg-${count.index}"
  description = "Security group for EKS worker nodes for VPC index ${count.index}"
  vpc_id      = var.vpc_ids[count.index]

  tags = merge(var.tags, {
    Name = "eks-worker-sg-${count.index}"
  })
}

# Worker <-> Worker communication
resource "aws_security_group_rule" "worker_self" {
  count = var.create_vpc
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_sg[count.index].id
  source_security_group_id = aws_security_group.eks_worker_sg[count.index].id
}

# All outbound allowed
resource "aws_security_group_rule" "worker_outbound" {
  count = var.create_vpc
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_worker_sg[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
}
