variable "hub_cluster_name" {
  description = "Hub Cluster Name"
  type        = string
  default     = "kubecon"
}

variable "region" {
  description = "Hub Cluster Region"
  type        = string
  default     = "us-west-2"
}

variable "domain_private_zone" {
  description = "Is ArgoCD private zone"
  type        = bool
  default     = false
}

variable "argocd_sso_cli_client_id" {
  description = "ArgoCD SSO OIDC cliClientID"
  type        = string
  default     = ""
}

variable "argocd_sso_client_id" {
  description = "ArgoCD SSO OIDC clientID"
  type        = string
  default     = ""
}

variable "argocd_enable_sso" {
  description = "Enable SSO for ArgoCD"
  type        = bool
  default     = false
}

variable "argocd_sso_client_secret" {
  description = "ArgoCD SSO OIDC clientSecret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_sso_issuer" {
  description = "ArgoCD SSO OIDC issuer"
  type        = string
  default     = ""
}

variable "argocd_sso_logout_url" {
  description = "ArgoCD SSO OIDC logoutURL"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain Name"
  type        = string
  default     = ""
}

variable "enable_ingress" {
  description = "Enable ingress"
  type        = bool
  default     = false
}


variable "workloads" {
  description = "Workloads"
  type        = any
  default     = {
    # This shows how to deploy an application to leverage cluster generator  https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/
    application-set = {
      add_on_application = false
      path               = "apps/application-sets"
      repo_url           = "https://github.com/csantanapr/argocd-scaling-example.git"
    }

  }
}

variable "enable_workloads" {
  description = "Enable Workloads with Application Sets"
  type        = bool
  default     = true
}

