output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}

output "ecs_kafka_ec2_sg_id" {
  value = aws_security_group.ecs_ec2.id
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.ecs_capacity.name
}

output "kafka_asg_name" {
  value = aws_autoscaling_group.ecs_kafka_asg.name
}
