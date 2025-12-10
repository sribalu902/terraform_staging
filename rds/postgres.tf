###############################################
# CREATE ONE RDS PER VPC (Dynamic)
###############################################

resource "aws_db_subnet_group" "postgres" {
  for_each = toset(var.vpc_indexes)

  name       = "${var.identifier_prefix}-${each.key}-subnet-group"
  subnet_ids = var.private_subnet_ids[tonumber(each.key)]

  tags = {
    Name = "${var.identifier_prefix}-${each.key}-subnet-group"
  }
}

resource "aws_security_group" "postgres" {
  for_each     = toset(var.vpc_indexes)
  vpc_id       = var.vpc_ids[tonumber(each.key)]
  name         = "${var.identifier_prefix}-${each.key}-sg"
  description  = "RDS SG for VPC ${each.key}"

  ingress {
    description     = "Allow 5432 inbound from allowed security groups"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids[tonumber(each.key)]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  for_each = toset(var.vpc_indexes)

  identifier             = "${var.identifier_prefix}-${each.key}"
  engine                 = "postgres"
  engine_version         = var.engine_version

  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage

  db_name                = var.db_name
  username               = var.username
  password               = var.password

  db_subnet_group_name   = aws_db_subnet_group.postgres[each.key].name
  vpc_security_group_ids = [aws_security_group.postgres[each.key].id]

  publicly_accessible    = var.publicly_accessible
  skip_final_snapshot    = var.skip_final_snapshot

  tags = {
    Name = "${var.identifier_prefix}-${each.key}"
  }
}
