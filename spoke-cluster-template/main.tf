provider "aws" {
  region  = var.region
}

# Modify based in which account the hub cluster is located
provider "aws" {
  region  = var.hub_region
  alias   = "hub"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.name, "--region", var.region]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", local.name, "--region", var.region]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.name, "--region", var.region]
    command     = "aws"
  }
  load_config_file  = false
  apply_retry_count = 15
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.hub.endpoint
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.hub.certificate_authority[0].data), "")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.hub_cluster_name, "--region", var.region]
    command     = "aws"
  }
  alias = "hub"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.hub.endpoint
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.hub.certificate_authority[0].data), "")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.hub_cluster_name, "--region", var.region]
      command     = "aws"
    }
  }
  alias = "hub"
}

data "aws_eks_cluster" "hub" {
  provider = aws.hub
  name     = var.hub_cluster_name
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_iam_role" "argo_role" {
  provider = aws.hub
  name     = "${var.hub_cluster_name}-argocd-hub"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.argo_role.arn]
    }
  }
}

resource "aws_iam_role" "spoke_role" {
  name               = local.name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

locals {
  name = var.spoke_cluster_name

  cluster_version = "1.24"

  instance_type = "m5.large"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

################################################################################
# Cluster
################################################################################

#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.10"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = try(var.existing_vpc_id, module.vpc.vpc_id)
  subnet_ids = try(var.existing_vpc_private_subnets, module.vpc.private_subnets)


  # Team Access
  manage_aws_auth_configmap = true
  aws_auth_roles = flatten([
    {
      rolearn  = aws_iam_role.spoke_role.arn # Granting access to ArgoCD from hub cluster
      username = "gitops-role"
      groups   = ["system:masters"]
    }
  ])

  eks_managed_node_groups = try(var.enable_existing_eks_managed_node_groups, false) ? var.existing_eks_managed_node_groups : {
    initial = {
      instance_types = [local.instance_type]

      min_size     = 3
      max_size     = 10
      desired_size = 5
    }
  }

  tags = local.tags
}


################################################################################
# Create Namespace and ArgoCD Project for Spoke Cluster "cluster-*"
################################################################################

resource "helm_release" "argocd_project" {
  provider         = helm.hub
  name             = "argo-project-${local.name}"
  chart            = "${path.module}/argo-project"
  namespace        = "argocd"
  create_namespace = true
  values = [
    yamlencode(
      {
        name = local.name
        spec : {
          sourceNamespaces : [
            local.name
          ]
        }
      }
    )
  ]
}

################################################################################
# Create secret in cluster-hub to register in ArgoCD
################################################################################

resource "kubernetes_secret_v1" "spoke_cluster" {
  provider = kubernetes.hub
  metadata {
    name      = local.name
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" : "cluster"
      "environment" : var.environment
    }
    annotations = {
      "project" : local.name
    }
  }
  data = {
    server = module.eks.cluster_endpoint
    name   = local.name
    config = jsonencode(
      {
        execProviderConfig : {
          apiVersion : "client.authentication.k8s.io/v1beta1",
          command : "argocd-k8s-auth",
          args : [
            "aws",
            "--cluster-name",
            local.name,
            "--role-arn",
            aws_iam_role.spoke_role.arn
          ],
          env : {
            AWS_REGION : var.region
          }
        },
        tlsClientConfig : {
          insecure : false,
          caData : module.eks.cluster_certificate_authority_data
        }
      }
    )
  }
  # Need to create ArgoCD project before creating secret
  # When secret is created the ArgoCD Application Set is activated
  # using the Cluster Generator, and create ArgoCD Apps specifying the ArgoCD Project
  depends_on = [helm_release.argocd_project]
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  create_vpc = try(var.create_vpc, true)
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
