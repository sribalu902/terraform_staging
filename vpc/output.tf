output "vpc_id" {
    description = "The ID of the VPC"
    value       = aws_vpc.nbsl_vpc.id
  
}
output "public_subnet_id" {
    description = "The ID of the public subnet"
    value       = aws_subnet.public_subnets[*].id
  
}
output "private_subnet_id" {
    description = "The ID of the private subnet"
    value       = aws_subnet.private_subnets[*].id
  
}