# --------------------------------------------
# 1️⃣ Launch Template for EC2 configuration
# --------------------------------------------
resource "aws_launch_template" "nbsl_lt" {
  name_prefix   = "nbsl-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids

#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               set -ex
#               yum update -y
#               yum install -y docker
#               systemctl start docker
#               systemctl enable docker
#               usermod -aG docker ec2-user
#               docker run -d -p 80:80 nginx
#               echo "Docker installed successfully on ASG instance" > /home/ec2-user/docker_status.txt
#               EOF
#   )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "nsbl-asg-instance"
    }
  }
}

# --------------------------------------------
# 2️⃣ Auto Scaling Group
# --------------------------------------------
resource "aws_autoscaling_group" "nsbl_asg" {
  name                      = "nsbl-asg"
  desired_capacity           = var.desired_capacity
  max_size                   = var.max_size
  min_size                   = var.min_size
  vpc_zone_identifier        = var.aws_subnet_ids
  health_check_grace_period  = 300
  health_check_type          = "EC2"
  launch_template {
    id      = aws_launch_template.nsbl_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "nsbl-asg-ec2"
    propagate_at_launch = true
  }
}

# --------------------------------------------
# 3️⃣ Attach Target Group (Optional - for ALB)
# --------------------------------------------
# Uncomment this if you later attach a Load Balancer
# resource "aws_autoscaling_attachment" "asg_tg_attach" {
#   autoscaling_group_name = aws_autoscaling_group.bala_asg.id
#   alb_target_group_arn    = aws_lb_target_group.tg.arn
# }
