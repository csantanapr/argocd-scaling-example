
#---------------------------------------------------------------
# Spoke Clusters
#---------------------------------------------------------------


data "aws_vpc" "selected" {
  tags = {
    Name = "hub-cluster"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

output "subnet_ids" {
  value = data.aws_subnets.private.ids
}
output "vpc_id" {
  value = data.aws_vpc.selected.id
}


module "spoke_cluster_1" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-us-west-2-1"
  region = "us-west-2"
  create_vpc = false
  existing_vpc_id = data.aws_vpc.selected.id
  existing_vpc_private_subnets = data.aws_subnets.private.ids
  hub_cluster_name   = "hub-cluster"
  environment        = "dev"
  enable_existing_eks_managed_node_groups = true
  existing_eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }
}

output "spoke_cluster_1" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.spoke_cluster_1.configure_kubectl
}

module "spoke_cluster_10" {
  source = "../spoke-cluster-template"

  spoke_cluster_name = "cluster-us-west-2-10"
  region = "us-west-2"
  create_vpc = false
  existing_vpc_id = data.aws_vpc.selected.id
  existing_vpc_private_subnets = data.aws_subnets.private.ids
  hub_cluster_name   = "hub-cluster"
  environment        = "dev"
  enable_existing_eks_managed_node_groups = true
  existing_eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.micro"]

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }
}

output "spoke_cluster_10" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.spoke_cluster_10.configure_kubectl
}



