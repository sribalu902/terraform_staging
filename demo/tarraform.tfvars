# terraform.tfvars (example values)
aws_region = "ap-south-1"
project = "demo-ecs"
environment = "dev"

key_name = "my-ssh-key"    # provide your keypair name
db_password = "cdspwd"     # DO NOT commit real secrets

onix_image = "488514412303.dkr.ecr.ap-south-1.amazonaws.com/onix:latest"
kafka_ui_image = "provectuslabs/kafka-ui:latest"
cds_image = "488514412303.dkr.ecr.ap-south-1.amazonaws.com/cds:latest"
redis_image = "redis:7-alpine"
