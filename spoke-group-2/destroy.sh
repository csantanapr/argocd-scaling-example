#!/bin/bash

CLUSTERS=10
COUNTER=0
for CLUSTER in $(seq $CLUSTERS)
do
    let COUNTER++
    echo "Destroying Clustert ${CLUSTER}"
    set -x
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.eks_blueprints_argocd_addons" -auto-approve
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.eks_blueprints_kubernetes_addons" -auto-approve
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.eks" -auto-approve
    terraform destroy -target="module.spoke_cluster_${CLUSTER}.module.vpc" -auto-approve
done
# Destroy the global
terraform destroy -auto-approve
