################################################################################
# Spoke Clusters Group 1
################################################################################

locals {
  region           = "us-west-2"
  cluster_version  = "1.24"
  hub_cluster_name = "kubecon"
  existing_eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }
}

module "spoke_cluster_1" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-1"

  region                                  = local.region
  create_vpc                              = local.create_vpc
  existing_vpc_id                         = local.existing_vpc_id
  existing_vpc_private_subnets            = local.existing_vpc_private_subnets
  hub_cluster_name                        = local.hub_cluster_name
  cluster_version                         = local.cluster_version
  enable_existing_eks_managed_node_groups = local.enable_existing_eks_managed_node_groups
  existing_eks_managed_node_groups        = local.existing_eks_managed_node_groups
  cluster_addons                          = local.cluster_addons
  addons                                  = local.addons
  enable_workloads                        = true
  enable_team_workloads                   = local.enable_team_workloads

  workloads = {
    "cluster-${local.region}-1-workload" = {
      add_on_application = false
      path               = "helm-guestbook"
      repo_url           = "https://github.com/argoproj/argocd-example-apps.git"
      target_revision    = "master"
      project            = "cluster-${local.region}-1"
      destination        = module.spoke_cluster_1.cluster_endpoint
      namespace          = "single-workload"
    }
  }

}

module "spoke_cluster_2" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-2"

  region                                  = local.region
  create_vpc                              = local.create_vpc
  existing_vpc_id                         = local.existing_vpc_id
  existing_vpc_private_subnets            = local.existing_vpc_private_subnets
  hub_cluster_name                        = local.hub_cluster_name
  cluster_version                         = local.cluster_version
  enable_existing_eks_managed_node_groups = local.enable_existing_eks_managed_node_groups
  existing_eks_managed_node_groups        = local.existing_eks_managed_node_groups
  cluster_addons                          = local.cluster_addons
  addons                                  = local.addons
  enable_workloads                        = local.enable_workloads
  enable_team_workloads                   = local.enable_team_workloads
}

module "spoke_cluster_10" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-${local.region}-10"

  region                                  = local.region
  create_vpc                              = local.create_vpc
  existing_vpc_id                         = local.existing_vpc_id
  existing_vpc_private_subnets            = local.existing_vpc_private_subnets
  hub_cluster_name                        = local.hub_cluster_name
  cluster_version                         = local.cluster_version
  enable_existing_eks_managed_node_groups = local.enable_existing_eks_managed_node_groups
  existing_eks_managed_node_groups        = local.existing_eks_managed_node_groups
  cluster_addons                          = local.cluster_addons
  addons                                  = local.addons
  enable_workloads                        = local.enable_workloads
  enable_team_workloads                   = local.enable_team_workloads
}


################################################################################
# Common
################################################################################

provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name                                    = "kubecon-spoke"
  vpc_cidr                                = "10.0.0.0/16"
  azs                                     = slice(data.aws_availability_zones.available.names, 0, 3)
  create_vpc                              = false
  existing_vpc_id                         = module.vpc.vpc_id
  existing_vpc_private_subnets            = module.vpc.private_subnets
  enable_existing_eks_managed_node_groups = true
  addons = {
    enable_metrics_server = true
  }
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  enable_workloads      = false
  enable_team_workloads = false

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/csantanapr/argocd-scaling-example"
  }
}





################################################################################
# Supporting Resources
################################################################################

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
