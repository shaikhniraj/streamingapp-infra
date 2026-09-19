include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ingress-nginx"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name                       = "mock-cluster"
    cluster_endpoint                   = "https://mock.example.com"
    cluster_certificate_authority_data = "bW9jaw=="   # base64 for the literal text "mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  cluster_name           = dependency.eks.outputs.cluster_name
  cluster_endpoint       = dependency.eks.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.eks.outputs.cluster_certificate_authority_data
  aws_region             = "us-east-1"
}