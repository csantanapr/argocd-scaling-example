#!/bin/bash

set -x

# Delete the Ingress before removing the addons
kubectl_login=$(terraform output -raw configure_kubectl)
$kubectl_login
kubectl delete ing -A --all

terraform destroy -target="grafana_dashboard.argocd" -auto-approve
terraform destroy -target="grafana_data_source.prometheus" -auto-approve
terraform destroy -target="helm_release.keycloak" -auto-approve

terraform destroy -target="module.eks_blueprints_argocd_workloads" -auto-approve
terraform destroy -target="module.eks_blueprints_argocd_addons" -auto-approve
terraform destroy -target="module.eks_blueprints_kubernetes_addons" -auto-approve
terraform destroy -target="module.eks" -auto-approve
terraform destroy -target="module.vpc" -auto-approve
terraform destroy -auto-approve
