#!/bin/bash

set -xe

terraform destroy -target="module.spoke_cluster.module.eks_blueprints_argocd_workloads" -auto-approve
terraform destroy -target="module.spoke_cluster.module.eks_blueprints_argocd_addons" -auto-approve
terraform destroy -target="module.spoke_cluster.module.eks_blueprints_kubernetes_addons" -auto-approve
terraform destroy -target="module.spoke_cluster.module.eks" -auto-approve
terraform destroy -target="module.spoke_cluster.module.vpc" -auto-approve
terraform destroy -auto-approve
