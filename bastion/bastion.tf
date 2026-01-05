############################################
# Bastion Security Group (one per VPC)
############################################
resource "aws_security_group" "bastion_sg" {
  count = length(var.vpc_ids)

  name        = "bastion-${count.index}-sg"
  description = "SG for Bastion Host in VPC ${count.index}"
  vpc_id      = var.vpc_ids[count.index]

  ingress {
    description = "Allow SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]  # Your laptop IP
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################
# Bastion EC2 Instance (one per VPC)
############################################
resource "aws_instance" "bastion" {
  count         = length(var.vpc_ids)
  ami           = var.ami_id
  instance_type = "t3.small"

  key_name = var.key_name

  subnet_id              = var.public_subnet_ids[count.index][0]
  vpc_security_group_ids = [aws_security_group.bastion_sg[count.index].id]

  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
set -e

apt-get update -y
apt-get install -y unzip curl

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

curl -LO https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.0/2024-09-12/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/
EOF

  tags = {
    Name = "bastion-${count.index}"
  }
}
