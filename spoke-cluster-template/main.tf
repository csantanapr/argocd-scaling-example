provider "aws" {
  region = var.region
}

# Modify based in which account the hub cluster is located
provider "aws" {
  region = var.hub_region
  alias  = "hub"
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
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true
  enable_irsa                    = var.eks_enable_irsa

  cluster_addons = try(var.cluster_addons, {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  })

  vpc_id     = var.create_vpc ? module.vpc.vpc_id : var.existing_vpc_id
  subnet_ids = var.create_vpc ? module.vpc.private_subnets : var.existing_vpc_private_subnets


  # Team Access
  manage_aws_auth_configmap = true
  aws_auth_roles = flatten([
    {
      rolearn  = aws_iam_role.spoke_role.arn # Granting access to ArgoCD from hub cluster
      username = "gitops-role"
      groups   = ["system:masters"]
    },
    module.admin_team.aws_auth_configmap_role,
    [for team in module.app_teams : team.aws_auth_configmap_role],
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
# EKS Blueprints Add-Ons IRSA config
################################################################################

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons?ref=3e64d809ac9dbc89aee872fe0f366f0b757d3137"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider     = module.eks.oidc_provider
  oidc_provider_arn = module.eks.oidc_provider_arn

  argocd_manage_add_ons = true # Indicates addons to be install via ArgoCD


  # EKS Add-ons (Some addons required custom configuration, review the specifc addon documentation and add any required configuration below)
  enable_aws_load_balancer_controller          = try(var.addons.enable_aws_load_balancer_controller, false)
  enable_metrics_server                        = try(var.addons.enable_metrics_server, false)
  enable_external_dns                          = try(var.addons.enable_external_dns, false)
  enable_amazon_prometheus                     = try(var.addons.enable_amazon_prometheus, false)
  enable_prometheus                            = try(var.addons.enable_prometheus, false)
  enable_kube_prometheus_stack                 = try(var.addons.enable_kube_prometheus_stack, false)
  enable_efs_csi_driver                        = try(var.addons.enable_efs_csi_driver, false)
  enable_efs_csi_driver_gitops                 = true
  enable_aws_fsx_csi_driver                    = try(var.addons.enable_aws_fsx_csi_driver, false)
  enable_ingress_nginx                         = try(var.addons.enable_ingress_nginx, false)
  enable_aws_for_fluentbit                     = try(var.addons.enable_aws_for_fluentbit, false)
  enable_cloudwatch_metrics                    = try(var.addons.enable_cloudwatch_metrics, false)
  enable_cloudwatch_metrics_gitops             = true
  enable_argo_workflows                        = try(var.addons.enable_argo_workflows, false)
  enable_argo_rollouts                         = try(var.addons.enable_argo_rollouts, false)
  enable_aws_node_termination_handler          = try(var.addons.enable_aws_node_termination_handler, false)
  enable_karpenter                             = try(var.addons.enable_karpenter, false)
  karpenter_enable_spot_termination_handling   = try(var.addons.karpenter_enable_spot_termination_handling, false)
  enable_vpa                                   = try(var.addons.enable_vpa, false)
  enable_aws_privateca_issuer                  = try(var.addons.enable_aws_privateca_issuer, false)
  enable_opentelemetry_operator                = try(var.addons.enable_opentelemetry_operator, false)
  enable_amazon_eks_adot                       = try(var.addons.enable_amazon_eks_adot, false)
  enable_velero                                = try(var.addons.enable_velero, false)
  enable_secrets_store_csi_driver_provider_aws = try(var.addons.enable_secrets_store_csi_driver_provider_aws, false)
  enable_secrets_store_csi_driver              = try(var.addons.enable_secrets_store_csi_driver, false)
  enable_external_secrets                      = try(var.addons.enable_external_secrets, false)
  enable_grafana                               = try(var.addons.enable_grafana, false)
  enable_promtail                              = try(var.addons.enable_promtail, false)
  enable_gatekeeper                            = try(var.addons.enable_gatekeeper, false)
  enable_cluster_autoscaler                    = try(var.addons.enable_cluster_autoscaler, false)
  cluster_autoscaler_helm_config = {
    set = [
      {
        name  = "podLabels.prometheus\\.io/scrape",
        value = "true",
        type  = "string",
      }
    ]
  }
  enable_cert_manager = try(var.addons.enable_cert_manager, false)
  cert_manager_helm_config = {
    set_values = [
      {
        name  = "extraArgs[0]"
        value = "--enable-certificate-owner-ref=false"
      },
    ]
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
# EKS Blueprints Add-Ons via ArgoCD
################################################################################

module "eks_blueprints_argocd_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/argocd?ref=3e64d809ac9dbc89aee872fe0f366f0b757d3137"
  providers = {
    helm       = helm.hub
    kubernetes = kubernetes.hub
  }

  argocd_skip_install = true # Indicates this is a remote cluster for ArgoCD

  helm_config = {
    namespace = local.name # Use cluster name as namespace for ArgoCD Apps
  }

  applications = {
    # This shows how to deploy Cluster addons using ArgoCD App of Apps pattern
    "${var.environment}-addons" = {
      add_on_application = true
      path               = "chart"
      repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
      #repo_url             = "git@github.com:aws-samples/eks-blueprints-add-ons.git"
      #ssh_key_secret_name  = "github-ssh-key" # Needed for private repos
      #git_secret_namespace = "argocd"
      #git_secret_name      = "${local.name}-addons"
      target_revision = "main"
      project         = local.name
      values = {
        destinationServer = module.eks.cluster_endpoint # Indicates the location of the remote cluster to deploy Addons
        argoNamespace     = local.name                  # Namespace to create ArgoCD Apps
        argoProject       = local.name                  # Argo Project
        targetRevision    = "main"
      }
    }
  }


  addon_config = { for k, v in module.eks_blueprints_kubernetes_addons.argocd_addon_config : k => v if v != null }

  addon_context = {
    aws_region_name                = var.region
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    eks_cluster_id                 = module.eks.cluster_name
  }

  # The Cluster secret needs to be created before creating ArgoCD Applications for Addons
  # ArgoCD Apps will have the remote cluster as destination
  depends_on = [kubernetes_secret_v1.spoke_cluster]
}


################################################################################
# EKS Workloads via ArgoCD
################################################################################

module "eks_blueprints_argocd_workloads" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/argocd?ref=3e64d809ac9dbc89aee872fe0f366f0b757d3137"
  providers = {
    helm       = helm.hub
    kubernetes = kubernetes.hub
  }
  count = try(var.enable_workloads, true) ? 1 : 0

  argocd_skip_install = true # Indicates this is a remote cluster for ArgoCD
  helm_config = {
    namespace = local.name # Use cluster name as namespace for ArgoCD Apps
  }

  applications = try(var.workloads, {
    # This shows how to deploy a multiple workloads using ArgoCD App of Apps pattern
    "${var.environment}-workloads" = {
      add_on_application = false
      path               = "envs/${var.environment}"
      repo_url           = "https://github.com/csantanapr/eks-blueprints-workloads.git"
      #repo_url             = "git@github.com:aws-samples/eks-blueprints-workloads.git"
      #ssh_key_secret_name  = "github-ssh-key"# Needed for private repos
      #git_secret_namespace = "argocd"
      #git_secret_name      = "${local.name}-workloads"
      target_revision = "argo-multi-cluster" #TODO change to main once git repo is updated
      project         = local.name
      values = {
        destinationServer = "https://kubernetes.default.svc" # Indicates the location where ArgoCD is installed, in this case hub cluster
        argoNamespace     = local.name                       # Namespace to create ArgoCD Apps
        argoProject       = local.name                       # Argo Project
        spec = {
          destination = {
            server = module.eks.cluster_endpoint # Indicates the location of the remote cluster to deploy Apps
          }
          source = {
            repoURL = "https://github.com/csantanapr/eks-blueprints-workloads.git"
            #repoURL        = "git@github.com:aws-samples/eks-blueprints-workloads.git"
            targetRevision = "argo-multi-cluster" #TODO change to main once git repo is updated
          }
          ingress = {
            argocd = false
          }
        }
      }
    }

    # This shows how to deploy a workload using a single ArgoCD App
    "${var.environment}-workload" = {
      add_on_application = false
      path               = "helm-guestbook"
      repo_url           = "https://github.com/argoproj/argocd-example-apps.git"
      target_revision    = "master"
      project            = local.name
      destination        = module.eks.cluster_endpoint
      namespace          = "single-workload"
    }

  })


  addon_context = {
    aws_region_name                = var.region
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    eks_cluster_id                 = module.eks.cluster_name
  }

  # The addons need to be present by the time the workloads are deployed
  # On destroy the workloads need to be remove before the addons
  depends_on = [module.eks_blueprints_argocd_addons]
}

################################################################################
# Teams
################################################################################

module "admin_team" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-teams?ref=v0.2.0"

  name = "admin-team"

  enable_admin = true
  users        = [data.aws_caller_identity.current.arn]
  cluster_arn  = module.eks.cluster_arn

  tags = local.tags
  depends_on = [module.eks_blueprints_argocd_addons]
}

module "app_teams" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-teams?ref=v0.2.0"

  for_each = {
    frontend = {}
    crystal  = {}
    nodejs   = {}
  }
  name = "app-team-${each.key}"
  create_iam_role = false


  users        = [data.aws_caller_identity.current.arn]
  cluster_arn  = module.eks.cluster_arn


  namespaces = {

    "backend-${each.key}" = {
      create_service_account = false

      labels = {
        appName     = "eks-teams-app",
        projectName = "project--eks-blueprints",
      }

      resource_quota = {
        hard = {
          "limits.cpu"      = "4",
          "limits.memory"   = "16Gi",
          "requests.cpu"    = "2",
          "requests.memory" = "4Gi",
          "pods"            = "20",
          "secrets"         = "20",
          "services"        = "20"
        }
      }
      limit_range = {
        limit = [
          {
            type = "Pod"
            max = {
              cpu    = "2"
              memory = "1Gi"
            }
          },
          {
            type = "Container"
            default = {
              cpu    = "500m"
              memory = "512Mi"
            }
            default_request = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        ]
      }
    }
  }


  tags = local.tags
  depends_on = [module.eks_blueprints_argocd_addons]
}


################################################################################
# EKS Workloads for Teams via ArgoCD
################################################################################

module "eks_blueprints_argocd_team_workloads" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/argocd?ref=3e64d809ac9dbc89aee872fe0f366f0b757d3137"
  providers = {
    helm       = helm.hub
    kubernetes = kubernetes.hub
  }
  count = try(var.enable_team_workloads, true) ? 1 : 0

  argocd_skip_install = true # Indicates this is a remote cluster for ArgoCD
  helm_config = {
    namespace = local.name # Use cluster name as namespace for ArgoCD Apps
  }

  applications = {
    # This shows how to deploy a multiple workloads using ArgoCD App of Apps pattern
    "${var.environment}-team-workloads" = {
      add_on_application = false
      path               = "multi-repo/argo-app-of-apps/${var.environment}"
      repo_url           = "https://github.com/csantanapr/eks-blueprints-workloads.git" #TODO change to https://github.com/aws-samples/eks-blueprints-workloads once git repo is updated
      #repo_url             = "git@github.com:aws-samples/eks-blueprints-workloads.git"
      #ssh_key_secret_name  = "github-ssh-key"# Needed for private repos
      #git_secret_namespace = "argocd"
      #git_secret_name      = "${local.name}-workloads"
      target_revision = "argo-multi-cluster" #TODO change to main once git repo is updated
      project         = local.name
      values = {
        destinationServer = module.eks.cluster_endpoint # Indicates the location of the remote cluster to deploy Apps
        argoNamespace     = local.name                  # Namespace to create ArgoCD Apps
        sourceNamespaces  = [local.name]
        spec = {
          apps = {
            ecsdemoFrontend = {
              createProject = true
              name          = "backend-frontend"
              project       = "backend-frontend-${var.environment}"
              namespace     = "backend-frontend"
              helm = {
                parameters = [
                  {
                    name : "ecsdemoCrystal.namespace"
                    value : "backend-crystal"
                  },
                  {
                    name : "ecsdemoNodejs.namespace"
                    value : "backend-nodejs"
                  }
                ]
              }
            }
            ecsdemoNodejs = {
              createProject = true
              name          = "backend-nodejs"
              project       = "backend-nodejs-${var.environment}"
              namespace     = "backend-nodejs"
              helm = {
                values = "fullnameOverride: ecsdemo-nodejs"
              }

            }
            ecsdemoCrystal = {
              createProject = true
              name          = "backend-crystal"
              project       = "backend-crystal-${var.environment}"
              namespace     = "backend-crystal"
              helm = {
                values = "fullnameOverride: ecsdemo-crystal"
              }

            }
          }
        }
      }
    }
  }

  addon_context = {
    aws_region_name                = var.region
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    eks_cluster_id                 = module.eks.cluster_name
  }

  # The addons need to be present by the time the workloads are deployed
  # On destroy the workloads need to be remove before the addons
  depends_on = [module.eks_blueprints_argocd_addons]
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  create_vpc = try(var.create_vpc, true)
  source     = "terraform-aws-modules/vpc/aws"
  version    = "~> 3.0"

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
