variable "hub_region" {
  description = "Hub Cluster Region"
  type        = string
  default     = "us-west-2"
}

variable "hub_cluster_name" {
  description = "Hub Cluster Name"
  type        = string
  default     = "kubecon-hub"
}

variable "region" {
  description = "Spoke Cluster Region"
  type        = string
  default     = "us-west-2"
}

variable "spoke_cluster_name" {
  description = "Spoke Cluster Name, name it prefix cluster-*"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Cluster Version"
  type        = string
  default     = "1.25"
}

variable "environment" {
  description = "Spoke Cluster Environment"
  type        = string
  default     = "dev"
}

variable "addons" {
  description = "Spoke Cluster Environment"
  type        = any
  default = {
    enable_metrics_server = true
  }
}

variable "workloads" {
  description = "Workloads"
  type        = any
  default     = null
}

variable "create_vpc" {
  description = "Create new VPC per cluster"
  type        = bool
  default     = false
}

variable "enable_existing_eks_managed_node_groups" {
  description = "Override managed groups"
  type        = bool
  default     = true
}

variable "cluster_addons" {
  description = "Managed Addons"
  type        = any
  default = {
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
}

variable "enable_workloads" {
  description = "Deploy sample workloads from EKS Blueprints"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC id"
  type        = string
  default     = ""
}

variable "existing_vpc_private_subnets" {
  description = "Private subnet ids"
  type        = list(string)
  default     = []
}

variable "enable_team_workloads" {
  description = "Deploy teams namespaces"
  type        = bool
  default     = false
}

variable "existing_eks_managed_node_groups" {
  description = "Managed Node Group"
  type        = any
  default = {
    initial = {
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }
}
