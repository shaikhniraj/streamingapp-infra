include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/monitoring"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name      = "mock-cluster"
    oidc_provider_arn = "arn:aws:iam::000000000000:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/MOCKMOCKMOCKMOCKMOCKMOCKMOCKMOCK"
    oidc_provider     = "oidc.eks.us-east-1.amazonaws.com/id/MOCKMOCKMOCKMOCKMOCKMOCKMOCKMOCK"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "ingress_nginx" {
  config_path = "../ingress-nginx"

  mock_outputs = {
    load_balancer_hostname = "mock123-456.us-east-1.elb.amazonaws.com"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  project      = "streamingapp"
  environment  = "dev"
  cluster_name = dependency.eks.outputs.cluster_name

  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_provider     = dependency.eks.outputs.oidc_provider

  ingress_elb_hostname = dependency.ingress_nginx.outputs.load_balancer_hostname

  # Fill in to get alarm emails, or leave blank and subscribe something
  # else (Slack/Teams/Telegram via SNS) to the topic later.
  alarm_email = ""
}
