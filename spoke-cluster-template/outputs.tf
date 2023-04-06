output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "cluster_endpoint" {
  description = "Cluster kube-api server endpoint url"
  value = module.eks.cluster_endpoint
}