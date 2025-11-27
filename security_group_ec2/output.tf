output "sg_ids" {
  value = aws_security_group.public_sg[*].id
}
