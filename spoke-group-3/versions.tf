terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }
  # ##  Used for end-to-end testing on project; update to suit your needs
  backend "s3" {
    region = "us-east-1"
    bucket = "csantanapr-terraform-states"
    key    = "gitops-blueprint/argocd-scaling-example/spoke-group-3/terraform.tfstate"
  }
}
