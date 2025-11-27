resource "aws_instance" "nbsl_ec2" {
  count = length(var.ec2_instance_names)

  ami           = var.ami_ids[count.index]
  instance_type = var.instance_types[count.index]

  # Every EC2 picks the SAME index subnet & SG
  subnet_id = var.subnet_ids[count.index]
  vpc_security_group_ids = [var.sg_ids[count.index]]

  key_name = var.key_name
  associate_public_ip_address = true


  ##############################
  # USER DATA — INSTALL DOCKER
  ##############################
  user_data = <<-EOF
              #!/bin/bash
              set -ex

              yum update -y

              # Install Docker
              amazon-linux-extras install docker -y || yum install docker -y
              systemctl enable docker
              systemctl start docker

              # Add ec2-user to docker group
              usermod -aG docker ec2-user

              # Pull & run a sample container
              docker run -d -p 80:80 nginx

              # Create a test log file
              echo "Docker installed on ${var.ec2_instance_names[count.index]}" > /home/ec2-user/docker_status.txt
              EOF

  tags = {
    Name = var.ec2_instance_names[count.index]
  }
}
