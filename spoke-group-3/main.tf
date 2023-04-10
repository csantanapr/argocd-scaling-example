################################################################################
# Spoke Clusters Group
################################################################################

locals {
  region = var.region
}

module "spoke_cluster_1" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-1"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_2" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-2"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_3" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-3"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_4" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-4"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_5" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-5"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_6" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-6"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_7" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-7"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_8" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-8"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_9" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-9"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_10" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-10"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_11" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-11"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_12" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-12"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_13" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-13"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_14" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-14"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_15" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-15"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_16" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-16"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_17" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-17"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_18" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-18"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_19" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-19"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_20" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-20"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}


module "spoke_cluster_21" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-21"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_22" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-22"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_23" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-23"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_24" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}

module "spoke_cluster_25" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-25"

  region                       = local.region
  existing_vpc_id              = module.vpc.vpc_id
  existing_vpc_private_subnets = module.vpc.private_subnets
  eks_enable_irsa              = false
}


################################################################################
# Supporting Resources
################################################################################

provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name     = "kubecon-spoke"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

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
