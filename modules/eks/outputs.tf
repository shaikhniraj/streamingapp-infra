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


