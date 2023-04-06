################################################################################
# Spoke Clusters Group 2
################################################################################

locals {
  region           = "eu-west-2"
}

module "spoke_cluster_1" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-1"

  region                                  = local.region
  existing_vpc_id                         = module.vpc.vpc_id
  existing_vpc_private_subnets            = module.vpc.private_subnets
}

module "spoke_cluster_2" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-2"

  region                                  = local.region
  existing_vpc_id                         = module.vpc.vpc_id
  existing_vpc_private_subnets            = module.vpc.private_subnets
}

module "spoke_cluster_10" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-10"

  region                                  = local.region
  existing_vpc_id                         = module.vpc.vpc_id
  existing_vpc_private_subnets            = module.vpc.private_subnets
}


################################################################################
# Supporting Resources
################################################################################

provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name                                    = "kubecon-spoke"
  vpc_cidr                                = "10.0.0.0/16"
  azs                                     = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/csantanapr/argocd-scaling-example"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
