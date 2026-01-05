#provider configuration for AWS in ap-south-1 region with backend s3
provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-nbsl-state"
    key    = "env/dec/terraform.tfstate"
    region = "ap-south-1"
  }
}