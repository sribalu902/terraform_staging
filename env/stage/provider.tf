#provider configuration for AWS in ap-south-1 region with backend s3
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.21"
    }
  }
}

provider "aws" {
  region = "ap-south-1"   # hard-coded to avoid backend variable issues
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




############################################
# FETCH CLUSTER DETAILS (DYNAMIC)
############################################

