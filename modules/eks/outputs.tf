output "cluster_endpoint" {
    value = module.eks.cluster_endpoint
    description = "The endpoint of the EKS cluster"

}
output "cluster_name" { 
    value = module.eks.cluster_name
    description = "The name of the EKS cluster" 
}

output "cluster_certificate_authority_data" {
    value = module.eks.cluster_certificate_authority_data
    description = "The certificate authority data for the EKS cluster"
}

# Needed by any module that grants a Kubernetes ServiceAccount an IAM role
# (IRSA) — e.g. the monitoring module's cloudwatch-agent role — the same way
# ebs_csi_irsa above already does internally.
output "oidc_provider_arn" {
    value = module.eks.oidc_provider_arn
    description = "ARN of this cluster's IAM OIDC identity provider, for building IRSA trust policies"
}

output "oidc_provider" {
    value = module.eks.oidc_provider
    description = "This cluster's OIDC issuer host (no https:// prefix), for the IRSA trust condition key"
}


