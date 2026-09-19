
// The official AWS EKS module handles complex IAM roles, security groups, and cluster settings automatically
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "us-east-1"]
  }
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}
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

// By default, the node security group only opens specific narrow ports
// (webhooks, kubelet, CoreDNS). Pod-to-pod traffic on APPLICATION ports
// (like our services' 80/3001-3004) between pods on DIFFERENT nodes needs
// an explicit rule — same-node pod traffic never hits security groups at
// all, which is why this only broke for cross-node calls (e.g. ingress-nginx
// reaching a frontend pod on another node), not for same-node kubelet checks.

node_security_group_additional_rules = {
  ingress_self_all = {
    description = "Allow all traffic between nodes in this cluster (pod-to-pod on any port)"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    type        = "ingress"
    self        = true
  }

  # NEW: lets the EKS control plane reach metrics-server pods directly for
  # the Metrics API aggregation layer. Not covered by the module's default
  # webhook rules (which only open 443/4443/6443/8443/9443) since
  # metrics-server serves on 10251 specifically.
  ingress_cluster_metrics_server = {
    description                   = "Allow EKS control plane to reach metrics-server for the Metrics API"
    protocol                      = "tcp"
    from_port                     = 10251
    to_port                       = 10251
    type                          = "ingress"
    source_cluster_security_group = true   # module-provided shorthand for "source = the cluster's own control-plane security group"
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

// Required for IRSA (IAM Roles for Service Accounts) to work — creates the
// OIDC identity provider that lets a Kubernetes ServiceAccount assume an IAM role
enable_irsa = true

// Installs the EBS CSI Driver as a managed EKS add-on — this is the actual
// controller that talks to the AWS EBS API to create/attach volumes for PVCs
cluster_addons = {
  aws-ebs-csi-driver = {
    most_recent              = true
    service_account_role_arn = aws_iam_role.ebs_csi_irsa.arn   # <-- was module.ebs_csi_irsa_role.iam_role_arn
  }
  metrics-server = {
    most_recent = true   # no service_account_role_arn needed — this add-on requires no IAM permissions at all
  }
}

}

# The trust policy: says WHO is allowed to assume this role. Here, specifically,
# the Kubernetes ServiceAccount "ebs-csi-controller-sa" in the "kube-system"
# namespace — proven via a signed OIDC token from THIS cluster's own OIDC
# provider, not just any AWS caller. This federation is what "IRSA" means.
data "aws_iam_policy_document" "ebs_csi_irsa_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    # Restricts the trust to exactly one ServiceAccount — without this,
    # ANY pod in the cluster with a projected OIDC token could assume this role
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# The actual IAM role, using the trust policy above
resource "aws_iam_role" "ebs_csi_irsa" {
  name               = "${var.project}-${var.environment}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_irsa_trust.json
}

# AWS's own pre-built managed policy — exactly the EBS create/attach/delete
# actions the CSI driver needs, maintained by AWS rather than us
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"   # makes this the default, so our StatefulSet's unlabeled volumeClaimTemplate picks it up automatically
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type = "gp3"   # gp3 over gp2 — newer generation, better price/performance
  }

  depends_on = [module.eks]
}