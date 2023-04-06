variable "hub_cluster_name" {
  description = "Hub Cluster Name"
  type        = string
  default     = "hub-cluster"
}
variable "spoke_cluster_name" {
  description = "Spoke Cluster Name"
  type        = string
  default     = "cluster-n"
}
variable "environment" {
  description = "Spoke Cluster Environment"
  type        = string
  default     = "dev"
}
variable "addons" {
  description = "Spoke Cluster Environment"
  type        = any
  default     = {}
}
# Multi-account Multi-region support
variable "region" {
  description = "Spoke Cluster Region"
  type        = string
  default     = "us-west-2"
}

variable "hub_region" {
  description = "Hub Cluster Region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_version" {
  description = "Cluster Version"
  type        = string
  default     = "1.24"
}

variable create_vpc {}
variable existing_vpc_id {}
variable existing_vpc_private_subnets {}
variable enable_existing_eks_managed_node_groups {}
variable existing_eks_managed_node_groups {}
variable enable_workloads {}
variable enable_team_workloads {}
variable cluster_addons {}