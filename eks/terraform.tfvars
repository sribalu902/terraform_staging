eks_version = "1.29"

node_ssh_key_name = "bala-eks-key"

node_groups = [
  # -------------------------------
  # SYSTEM NODE GROUP (ON-DEMAND)
  # -------------------------------
  {
    name           = "system-ng"
    instance_types = ["t3.small"]
    disk_size      = 20
    desired_size   = 1
    min_size       = 1
    max_size       = 2
  },

  # -------------------------------
  # APP NODE GROUP (ON-DEMAND)
  # -------------------------------
  {
    name           = "app-ng"
    instance_types = ["t3.medium"]
    disk_size      = 30
    desired_size   = 1
    min_size       = 1
    max_size       = 3
  },

  # -------------------------------
  # SPOT NODE GROUP
  # -------------------------------
  {
    name           = "spot-ng"
    instance_types = [
      "t3.medium",
      "t3.large",
      "t3a.medium",
      "t3a.large"
    ]
    disk_size      = 30
    desired_size   = 1
    min_size       = 0
    max_size       = 4
    capacity_type  = "SPOT"

    labels = {
      lifecycle = "spot"
      type      = "spot"
    }
  }
]

addons = [
  {
    name    = "vpc-cni"
    version = "v1.18.5-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.11.1-eksbuild.9"
  },
  {
    name    = "kube-proxy"
    version = "v1.29.0-eksbuild.1"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.29.1-eksbuild.1"
  }
]

tags = {
  Environment = "stage"
  Project     = "nbsl"
}