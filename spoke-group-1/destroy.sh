#!/bin/bash

set -x

CLUSTERS=3
COUNTER=0
for CLUSTER in $(seq $CLUSTERS)
do
    let COUNTER++
    echo "Destroying Clustert ${CLUSTER}"
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.eks_blueprints_argocd_workloads" -auto-approve
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.eks_blueprints_argocd_addons" -auto-approve
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.eks_blueprints_kubernetes_addons" -auto-approve
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.eks" -auto-approve
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.vpc" -auto-approve
done
# Destroy the global
terraform destroy -target="module.vpc" -auto-approve
terraform destroy -auto-approve
