# #provider configuration for AWS in ap-south-1 region with backend s3
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 6.21"
#     }
#   }
# }

# provider "aws" {
#   region = "ap-south-1"   # hard-coded to avoid backend variable issues
# }


# terraform {
#   backend "s3" {
#     bucket = "terraform-nbsl-state"
#     key    = "env/dec/terraform.tfstate"
#     region = "ap-south-1"
#   }
# }

terraform {
  required_version = ">= 1.9.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }
  backend "s3" {
    bucket         = "test-prod-nbsl"
    region         = "ap-south-1"
    key            = "env/test-prod/terraform.tfstate"
    dynamodb_table = "Lock-Files"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"
}