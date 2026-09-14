#Inherit remote state configuration and providers from your root terragrunt.hcl file 

include "root" {
    path = find_in_parent_folders()
}

# Points Terragrunt directly to the local Terraform module
terraform {
    source = "../../../modules/eks"  
}

# Supplies environment-specific inputs directly into the module's declared variables
inputs = {

project = "streamingapp"
environment = "dev"
cluster_version = "1.36"

# Replace with these your actual AWS VPC infrastructure 
vpc_id = "vpc-078495bdcf701be3c"
subnet_ids = [
  "subnet-020cea587a61ba678", # us-east-1a
  "subnet-0beb7033d32bf4590", # us-east-1b
  "subnet-02530a2c6d01075d8"  # us-east-1c
]

cluster_admin_role_arns = [
  "arn:aws:iam::586917955726:role/aws-reserved/sso.amazonaws.com/ap-south-1/AWSReservedSSO_AWSAdministratorAccess_1004171fe5443581",
  "arn:aws:iam::586917955726:user/niraj-cli"
]
}