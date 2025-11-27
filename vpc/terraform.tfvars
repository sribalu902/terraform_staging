#to give all the variable values for subnet creation with az"s
# create_vpc = 1

# vpc_cidrs = ["10.10.0.0/16"]

# public_subnet_cidrs = [
#   "10.10.1.0/24",
#   "10.10.2.0/24"
# ]

# private_subnet_cidrs = [
#   "10.10.3.0/24",
#   "10.10.4.0/24"
# ]

# public_subnets_per_vpc  = 2
# private_subnets_per_vpc = 2

# cluster_name = "nbsl"

create_vpc = 2
vpc_names = [ "cds", "bap"]
vpc_cidrs = [
  "10.10.0.0/16",
  "10.20.0.0/16",
  # "10.30.0.0/16"
]

public_subnet_cidrs = [
  "10.10.1.0/24", "10.10.2.0/24",
  "10.20.1.0/24", "10.20.2.0/24",
  # "10.30.1.0/24", "10.30.2.0/24"
]

private_subnet_cidrs = [
  "10.10.3.0/24", "10.10.4.0/24",
  "10.20.3.0/24", "10.20.4.0/24",
  # "10.30.3.0/24", "10.30.4.0/24"

]

public_subnet_azs = [
  "ap-south-1a", "ap-south-1b",
  "ap-south-1a", "ap-south-1b",
  # "us-east-1a", "us-east-1b"
]

private_subnet_azs = [
  "ap-south-1a","ap-south-1b",
  "ap-south-1a","ap-south-1b"
  ]

public_subnets_per_vpc  = 2
private_subnets_per_vpc = 2

cluster_names = ["cds" ,"bap"]



