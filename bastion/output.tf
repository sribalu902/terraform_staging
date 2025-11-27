output "bastion_public_ips" {
  value = aws_instance.bastion[*].public_ip
}

output "bastion_private_ips" {
  value = aws_instance.bastion[*].private_ip
}

output "sg_ids" {
  value = aws_security_group.bastion_sg[*].id
}

