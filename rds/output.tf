############################################################
# OUTPUT: RDS Endpoints (one per VPC index)
############################################################
output "db_endpoints" {
  description = "Map of RDS endpoints per VPC index"
  value = {
    for idx, db in aws_db_instance.postgres :
    idx => db.address
  }
}

############################################################
# OUTPUT: RDS Ports (constant, but exposed per VPC index)
############################################################
output "db_ports" {
  description = "Map of ports (always 5432) matching each DB"
  value = {
    for idx, db in aws_db_instance.postgres :
    idx => db.port
  }
}

############################################################
# OUTPUT: RDS Security Groups (per RDS / per VPC index)
############################################################
output "db_security_group_ids" {
  description = "Security Group IDs for each RDS instance"
  value = {
    for idx, sg in aws_security_group.postgres :
    idx => sg.id
  }
}

############################################################
# OUTPUT: Subnet Groups for each RDS instance
############################################################
output "db_subnet_group_names" {
  description = "Subnet group names used by RDS in each VPC"
  value = {
    for idx, sn in aws_db_subnet_group.postgres :
    idx => sn.name
  }
}
