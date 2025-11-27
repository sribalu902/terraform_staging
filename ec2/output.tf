output "instance_ids" {
  value = aws_instance.nbsl_ec2[*].id
}

