variable "project" {
    type = string 
    description = "The name of the project used for tagging and naming resource"
}

variable "environment" {
    type = string
    description = "The environment for the EKS cluster (e.g., dev, staging, prod)"
}

variable "cluster_version" {
    type = string
    description = "The version of the EKS cluster (e.g., 1.21, 1.22)"
}

variable "vpc_id" {
    type = string
    description = "The ID of the VPC where the EKS cluster will be created"
}

variable "subnet_ids" {
    type = list(string)
    description = "The IDs of the subnets where the EKS cluster will be created"
}
variable "cluster_admin_role_arns" {
  type        = list(string)
  description = "IAM role ARNs (e.g. federated SSO roles) to grant full admin access to the EKS cluster's Kubernetes RBAC, via EKS Access Entries"
  default     = []
}