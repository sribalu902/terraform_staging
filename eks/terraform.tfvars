eks_version = "1.29"

node_ssh_key_name = "bala-eks-key"

node_groups = [
  {
    name           = "system-ng"
    instance_types = ["t3.small"]
    disk_size      = 20
    desired_size   = 1
    min_size       = 1
    max_size       = 2
  },
  {
    name           = "app-ng"
    instance_types = ["t3.medium"]
    disk_size      = 30
    desired_size   = 1
    min_size       = 1
    max_size       = 3
  }
]

tags = {
  Environment = "stage"
  Project     = "nbsl"
}



