#provider configuration for AWS in ap-south-1 region with backend s3
provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket = "nsbl-terraform-state"
    key    = "env/dev/terraform.tfstate"
    region = "ap-south-1"
  }
}

# -------------------------
# Kubernetes providers (one per EKS cluster)
# NOTE: These depend on module.eks outputs — we'll run apply in two steps.
# -------------------------

# provider "kubernetes" {
#   alias                  = "cds"
#   host                   = module.eks[0].cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate)
#   token                  = data.aws_eks_cluster_auth.cds.token
# }

# provider "kubernetes" {
#   alias                  = "bap"
#   host                   = module.eks[1].cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks[1].cluster_certificate)
#   token                  = data.aws_eks_cluster_auth.bap.token
# }

# data "aws_eks_cluster_auth" "cds" {
#   name = module.eks[0].cluster_name
# }

# data "aws_eks_cluster_auth" "bap" {
#   name = module.eks[1].cluster_name
# }


#############################################
# DYNAMIC KUBERNETES PROVIDERS (one per EKS)
############################################
provider "kubernetes" {
  alias = each.key
  host  = each.value.cluster_endpoint
  token = each.value.token
  cluster_ca_certificate = base64decode(each.value.certificate)
}

# Build dynamic provider map (based on created EKS clusters)
locals {
  eks_providers = {
    for idx, eks in module.eks :
    var.cluster_names[idx] => {
      cluster_endpoint = eks.cluster_endpoint
      token            = data.aws_eks_cluster_auth.eks[idx].token
      certificate      = eks.cluster_certificate
    }
  }
}

# Create 'data' blocks dynamically
data "aws_eks_cluster" "eks" {
  for_each = toset(var.cluster_names)
  name     = module.eks[index(var.cluster_names, each.key)].cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  for_each = toset(var.cluster_names)
  name     = module.eks[index(var.cluster_names, each.key)].cluster_name
}
