output "ec2_instamnce_id" {
    value = aws_instance.nbsl_ec2[*].id
}

