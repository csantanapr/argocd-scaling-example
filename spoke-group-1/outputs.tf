output "spoke_kubeconfig" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value = [
    module.spoke_cluster_1.configure_kubectl,
    module.spoke_cluster_2.configure_kubectl,
    module.spoke_cluster_3.configure_kubectl,
    module.spoke_cluster_4.configure_kubectl,
    module.spoke_cluster_5.configure_kubectl,
    module.spoke_cluster_6.configure_kubectl,
    module.spoke_cluster_7.configure_kubectl,
    module.spoke_cluster_8.configure_kubectl,
    module.spoke_cluster_9.configure_kubectl,
    module.spoke_cluster_10.configure_kubectl
  ]
}

output "spoke_cluster_endpoint" {
  description = "Cluster kube-api server endpoint url"
  value = [
    module.spoke_cluster_1.cluster_endpoint,
    module.spoke_cluster_2.cluster_endpoint,
    module.spoke_cluster_3.cluster_endpoint,
    module.spoke_cluster_4.cluster_endpoint,
    module.spoke_cluster_5.cluster_endpoint,
    module.spoke_cluster_6.cluster_endpoint,
    module.spoke_cluster_7.cluster_endpoint,
    module.spoke_cluster_8.cluster_endpoint,
    module.spoke_cluster_9.cluster_endpoint,
    module.spoke_cluster_10.cluster_endpoint
  ]
}
