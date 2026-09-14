
// The official AWS EKS module handles complex IAM roles, security groups, and cluster settings automatically
module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"

// Naming cluster dynamically based on project and environment
cluster_name = "${var.project}-${var.environment}-cluster"
cluster_version= var.cluster_version

// Network configuration required by EKS 
vpc_id     = var.vpc_id
subnet_ids = var.subnet_ids

//Allow cluster API Server to be accessible from the public internet
cluster_endpoint_public_access = true

//Configure EKS managed node groups (Worker nodes running containers)
eks_managed_node_groups = {
    general = {
    
    instance_type = "t3.medium"
    # scalling configuration for the node group
    min_size     = 1
    max_size = 3
    desired_size = 2
    }

    // tags to all provisioned resources
    tags = {
        Project     = var.project
        Environment = var.environment
    }   
    
}

// EKS Access Entries: grants Kubernetes RBAC permissions to specific IAM principals.
// IAM authentication gets you INTO the cluster; this is the separate layer that decides
// what you're allowed to see/do once inside (pods, deployments, etc.).
// Without this, only the IAM principal that ran `terraform apply` has access by default.
access_entries = {
    // Loop over every ARN passed in via var.cluster_admin_role_arns, creating one
    // access entry per role. "admin-0", "admin-1" etc. are just internal map keys.
    for idx, role_arn in var.cluster_admin_role_arns : "admin-${idx}" => {
        principal_arn = role_arn   // the IAM role being granted access

        policy_associations = {
            admin = {
                // Full admin over all namespaces/resources in this cluster
                policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
                access_scope = {
                    type = "cluster"   // applies cluster-wide, not scoped to one namespace
                }
            }
        }
    }
}

}