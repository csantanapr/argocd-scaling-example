provider "aws" {
  region = var.region
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

# To get the hosted zone to be use in argocd domain
data "aws_route53_zone" "domain_name" {
  count        = var.enable_ingress ? 1 : 0
  name         = var.domain_name
  private_zone = var.domain_private_zone
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

locals {
  name = var.hub_cluster_name

  instance_type = "r6a.2xlarge" # Memory optimized 64GB RAM, 2vCPU, x86_64

  vpc_cidr  = "10.0.0.0/16"
  azs_count = 3
  azs       = slice(data.aws_availability_zones.available.names, 0, local.azs_count)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

  argocd_namespace  = "argocd"
  argocd_subdomain  = "argocd"
  argocd_domain_arn = try(data.aws_route53_zone.domain_name[0].arn, "")

  # ArgoCD Helm values for base
  argocd_values = templatefile("${path.module}/helm-argocd/values.yaml", {
    irsa_iam_role_arn = module.argocd_irsa.iam_role_arn
    host              = "${local.argocd_subdomain}.${var.domain_name}"
    enable_ingress    = var.enable_ingress
  })

  # ArgoCD Helm values for AWS Cognito SSO Login
  argocd_sso = var.argocd_enable_sso && var.enable_ingress ? templatefile("${path.module}/helm-argocd/cognito.yaml", {
    issuer       = var.argocd_sso_issuer
    clientID     = var.argocd_sso_client_id
    clientSecret = var.argocd_sso_client_secret
    logoutURL    = "${var.argocd_sso_logout_url}?client_id=${var.argocd_sso_client_id}&logout_uri=https://${local.argocd_subdomain}.${var.domain_name}/logout"
    cliClientID  = var.argocd_sso_cli_client_id
    url          = "https://${local.argocd_subdomain}.${var.domain_name}"
  }) : ""

  # Keycloak and AMG Config
  enable_keycloak                  = var.enable_ingress && length(var.domain_name) > 0
  keycloak_subdomain               = "keycloak"
  keycloak_admin_password_key_name = "keycloak"
  keycloak_admin_username          = "admin"
  keycloak_ingress_ready           = "300s"
  enable_amg                       = local.enable_keycloak

}

################################################################################
# EBS CSI Driver Role
################################################################################

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.14"

  role_name = "${local.name}-ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
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

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      most_recent              = true
    }
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

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = [local.instance_type]

      min_size     = 2
      max_size     = 3
      desired_size = 2
    }
  }

  tags = local.tags
}

################################################################################
# Kubernetes Addons
################################################################################

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons?ref=3e64d809ac9dbc89aee872fe0f366f0b757d3137" # TODO: Last update to hash 04=3/31/2023

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider     = module.eks.oidc_provider
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_argocd         = true
  argocd_manage_add_ons = true # Indicates that ArgoCD is responsible for managing/deploying add-ons
  argocd_helm_config = {
    namespace = local.argocd_namespace
    version   = "5.27.1" # ArgoCD v2.6.6
    values    = [local.argocd_values, local.argocd_sso]
  }

  # Add-ons
  enable_aws_load_balancer_controller = true                              # ArgoCD UI depends on aws-loadbalancer-controller for Ingress
  enable_metrics_server               = true                              # ArgoCD HPAs depend on metric-server
  enable_external_dns                 = var.enable_ingress ? true : false # ArgoCD Server and UI use valid https domain name
  external_dns_helm_config = {
    domainFilters : [var.domain_name]
    policy : "sync" # Allows to delete DNS records
  }
  external_dns_route53_zone_arns = [local.argocd_domain_arn] # ArgoCD Server and UI domain name is registered in Route 53

  # Observability for ArgoCD
  enable_prometheus                    = true
  enable_amazon_prometheus             = true
  amazon_prometheus_workspace_endpoint = module.managed_prometheus.workspace_prometheus_endpoint

  tags = local.tags
}

################################################################################
# EKS Blueprints Add-Ons via ArgoCD
################################################################################

module "eks_blueprints_argocd_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/argocd?ref=3e64d809ac9dbc89aee872fe0f366f0b757d3137" # TODO: Last update to hash 04=3/31/2023

  argocd_skip_install = true # Skip argocd controller install

  helm_config = {
    namespace        = local.argocd_namespace
    create_namespace = false
  }

  applications = {
    # This shows how to deploy Cluster addons using ArgoCD App of Apps pattern
    addons = {
      add_on_application = true
      path               = "chart"
      repo_url           = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
      target_revision    = "main" #TODO change main
      #repo_url             = "git@github.com:aws-samples/eks-blueprints-add-ons.git"
      #ssh_key_secret_name  = "github-ssh-key" # Needed for private repos
      #git_secret_namespace = "argocd"
      #git_secret_name      = "${local.name}-addons"
    }
  }

  addon_config = { for k, v in module.eks_blueprints_kubernetes_addons.argocd_addon_config : k => v if v != null }

  addon_context = {
    aws_region_name                = var.region
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    eks_cluster_id                 = module.eks.cluster_name
  }

  depends_on = [module.eks_blueprints_kubernetes_addons]
}


################################################################################
# EKS Workloads via ArgoCD
################################################################################

module "eks_blueprints_argocd_workloads" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/argocd?ref=3e64d809ac9dbc89aee872fe0f366f0b757d3137" # TODO: Last update to hash 04=3/31/2023

  count = try(var.enable_workloads, true) ? 1 : 0

  argocd_skip_install = true # Skip argocd controller install
  helm_config = {
    namespace        = local.argocd_namespace
    create_namespace = false
  }

  applications = try(var.workloads, {
    # This shows how to deploy an application to leverage cluster generator  https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/
    application-set = {
      add_on_application = false
      path               = "application-sets"
      repo_url           = "https://github.com/csantanapr/eks-blueprints-workloads.git" #TODO to aws-samples github org
      target_revision    = "argo-multi-cluster"                                         #TODO change to main
      #repo_url             = "git@github.com:aws-samples/eks-blueprints-workloads.git"
      #ssh_key_secret_name  = "github-ssh-key"# Needed for private repos
      #git_secret_namespace = "argocd"
      #git_secret_name      = "${local.name}-workloads"
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
# ArgoCD EKS Access
################################################################################

module "argocd_irsa" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints-addons//modules/eks-blueprints-addon?ref=3e64d809ac9dbc89aee872fe0f366f0b757d3137" # TODO: Last update to hash 04=3/31/2023

  create_release             = false
  create_role                = true
  role_name_use_prefix       = false
  role_name                  = "${module.eks.cluster_name}-argocd-hub"
  assume_role_condition_test = "StringLike"
  role_policies = {
    ArgoCD_EKS_Policy = aws_iam_policy.irsa_policy.arn
  }
  oidc_providers = {
    this = {
      provider_arn    = module.eks.oidc_provider_arn
      namespace       = local.argocd_namespace
      service_account = "argocd-*"
    }
  }
  tags = local.tags

}

resource "aws_iam_policy" "irsa_policy" {
  name        = "${module.eks.cluster_name}-argocd-irsa"
  description = "IAM Policy for ArgoCD Hub"
  policy      = data.aws_iam_policy_document.irsa_policy.json
  tags        = local.tags
}

data "aws_iam_policy_document" "irsa_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["sts:AssumeRole"]
  }
}

################################################################################
# AMP
################################################################################

module "managed_prometheus" {
  source  = "terraform-aws-modules/managed-service-prometheus/aws"
  version = "~> 2.2"

  workspace_alias = local.name

  tags = local.tags
}


################################################################################
# Keycloak
################################################################################

resource "random_password" "keycloak" {
  count = local.enable_keycloak ? 1 : 0

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "keycloak" {
  count = local.enable_keycloak ? 1 : 0

  name                    = local.keycloak_admin_password_key_name
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "keycloak" {
  count = local.enable_keycloak ? 1 : 0

  secret_id     = aws_secretsmanager_secret.keycloak[0].id
  secret_string = random_password.keycloak[0].result
}

resource "helm_release" "keycloak" {
  count = local.enable_keycloak ? 1 : 0

  name             = "keycloak"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "keycloak"
  version          = "13.4.0"
  namespace        = "keycloak"
  create_namespace = true


  values = [templatefile("${path.module}/helm-keycloak/values.yaml", {
    workspace_endpoint = module.managed_grafana.workspace_endpoint
    admin_username     = local.keycloak_admin_username
    password           = random_password.keycloak[0].result
    enable_ingress     = var.enable_ingress
    host               = "${local.keycloak_subdomain}.${var.domain_name}"
  })]

  depends_on = [module.eks_blueprints_kubernetes_addons]
}


################################################################################
# AMG
################################################################################

provider "grafana" {
  url  = try("https://${module.managed_grafana.workspace_endpoint}", null)
  auth = try(module.managed_grafana.workspace_api_keys.admin.key, "")
}

resource "grafana_data_source" "prometheus" {
  count = local.enable_amg ? 1 : 0

  type       = "prometheus"
  name       = "Prometheus"
  is_default = true
  url        = module.managed_prometheus.workspace_prometheus_endpoint

  json_data_encoded = jsonencode({
    httpMethod    = "POST"
    sigV4Auth     = true
    sigV4AuthType = "ec2_iam_role"
    sigV4Region   = var.region
  })

}

resource "grafana_dashboard" "argocd" {
  count = local.enable_amg ? 1 : 0

  config_json = file("${path.module}/grafana-argocd-dashboard.json")
}

module "managed_grafana" {
  source  = "terraform-aws-modules/managed-service-grafana/aws"
  version = "~> 1.9"

  create = local.enable_amg

  # Workspace
  name                     = local.name
  associate_license        = false
  description              = "AWS Managed Grafana service gitops example"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["PROMETHEUS"]
  workspace_api_keys = {
    admin = {
      key_name        = "admin"
      key_role        = "ADMIN"
      seconds_to_live = 2505600
    }
  }

  # SAML configuration will do after keycloak is installed
  create_saml_configuration = false

  tags = local.tags
}

# Wait for Keycloak ingress to be up
resource "time_sleep" "wait_keyclock_ingress" {
  count = local.enable_amg ? 1 : 0

  create_duration = local.keycloak_ingress_ready

  depends_on = [helm_release.keycloak]
}

resource "aws_grafana_workspace_saml_configuration" "this" {
  count = local.enable_amg ? 1 : 0

  workspace_id       = module.managed_grafana.workspace_id
  idp_metadata_url   = "https://${local.keycloak_subdomain}.${var.domain_name}/realms/keycloak-blog/protocol/saml/descriptor"
  editor_role_values = ["editor"]
  admin_role_values  = ["admin"]
  role_assertion     = "role"
  depends_on         = [time_sleep.wait_keyclock_ingress]
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

################################################################################
# ACM Certificate
################################################################################

resource "aws_acm_certificate" "cert" {
  count             = var.enable_ingress ? 1 : 0
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert" {
  count           = var.enable_ingress ? 1 : 0
  zone_id         = data.aws_route53_zone.domain_name[0].zone_id
  name            = tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_name
  type            = tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_type
  records         = [tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = var.enable_ingress ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert : record.fqdn]
}
