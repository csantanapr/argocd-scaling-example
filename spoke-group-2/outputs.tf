output "spoke_kubeconfig" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = [
    module.spoke_cluster_1.configure_kubectl,
    module.spoke_cluster_2.configure_kubectl,
    module.spoke_cluster_10.configure_kubectl
  ]
}
