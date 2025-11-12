# Multiple EC2 instances with Docker installation
# ------------------------------------------------------
resource "aws_instance" "nbsl_ec2" {
  count = length(var.ec2_instance_names)  # Dynamically create N EC2s
  ami                    = var.ami_ids[count.index]           # Different AMIs
  instance_type          = var.instance_types[count.index]    # Different instance types
  subnet_id              = var.subnet_id[count.index].id    # From your existing VPC
  vpc_security_group_ids = var.security_group_ids             # Security groups
  key_name               = var.key_name
  associate_public_ip_address = true

  # --------------------------------------------------
  # User Data: Install Docker & start container
  # --------------------------------------------------
#   user_data = <<-EOF
#               #!/bin/bash
#               set -ex
#               yum update -y

#               # Install Docker
#               yum install -y docker
#               systemctl start docker
#               systemctl enable docker

#               # Add ec2-user to docker group
#               usermod -aG docker ec2-user

#               # Pull and run a test container
#               docker run -d -p 80:80 nginx

#               # Create a test file with instance info
#               echo "Docker installed successfully on ${var.ec2_instance_names[count.index]}" > /home/ec2-user/docker_status.txt
#               EOF

  tags = {
    Name        = var.ec2_instance_names[count.index]
  }
}