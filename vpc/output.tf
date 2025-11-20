############################################
# VPC IDs
############################################
output "vpc_ids" {
  value = aws_vpc.multi_vpc[*].id
}

############################################
# VPC CIDRs
############################################
output "vpc_cidrs" {
  value = aws_vpc.multi_vpc[*].cidr_block
}

############################################
# PUBLIC SUBNET IDS (grouped by VPC)
############################################
output "public_subnet_ids" {
  value = [
    for vpc_index in range(var.create_vpc) : [
      for id in flatten([
        for sn in aws_subnet.public :
        sn.vpc_id == aws_vpc.multi_vpc[vpc_index].id ? sn.id : null
      ]) : id if id != null
    ]
  ]
}

############################################
# PRIVATE SUBNET IDS (grouped by VPC)
############################################
output "private_subnet_ids" {
  value = [
    for vpc_index in range(var.create_vpc) : [
      for id in flatten([
        for sn in aws_subnet.private :
        sn.vpc_id == aws_vpc.multi_vpc[vpc_index].id ? sn.id : null
      ]) : id if id != null
    ]
  ]
}

############################################
# PUBLIC ROUTE TABLES
############################################
output "public_route_table_ids" {
  value = aws_route_table.public_rt[*].id
}

############################################
# PRIVATE ROUTE TABLE IDS (grouped by VPC)
############################################
output "private_route_table_ids" {
  value = [
    for vpc_index in range(var.create_vpc) : compact([
      for rt in aws_route_table.private_rt :
      rt.vpc_id == aws_vpc.multi_vpc[vpc_index].id ? rt.id : null
    ])
  ]
}

##