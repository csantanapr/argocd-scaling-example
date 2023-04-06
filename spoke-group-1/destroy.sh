#!/bin/bash

set -xe

terraform destroy -target="module.spoke_cluster_1.module.eks_blueprints_argocd_workloads" -auto-approve
terraform destroy -target="module.spoke_cluster_1.module.eks_blueprints_argocd_addons" -auto-approve
terraform destroy -target="module.spoke_cluster_1.module.eks_blueprints_kubernetes_addons" -auto-approve
terraform destroy -target="module.spoke_cluster_1.module.eks" -auto-approve
terraform destroy -target="module.spoke_cluster_1.module.vpc" -auto-approve
terraform destroy -auto-approve

terraform destroy -target="module.spoke_cluster_10.module.eks_blueprints_argocd_workloads" -auto-approve
terraform destroy -target="module.spoke_cluster_10.module.eks_blueprints_argocd_addons" -auto-approve
terraform destroy -target="module.spoke_cluster_10.module.eks_blueprints_kubernetes_addons" -auto-approve
terraform destroy -target="module.spoke_cluster_10.module.eks" -auto-approve
terraform destroy -target="module.spoke_cluster_10.module.vpc" -auto-approve
terraform destroy -auto-approve
