###############################################
# SECURITY GROUP FOR EC2 (ONE SG PER VPC)
###############################################

resource "aws_security_group" "public_sg" {
  count       = length(var.vpc_ids)

  name        = "${var.sg_name_prefix}-${count.index}"
  description = "Allow SSH/HTTP for EC2 in VPC ${count.index}"

  vpc_id = var.vpc_ids[count.index]

  ########################################
  # INGRESS RULES
  ########################################

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  

  ########################################
  # OUTBOUND
  ########################################
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.sg_name_prefix}-${count.index}"
  }
}


