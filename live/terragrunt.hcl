locals {
    aws_region = "us-east-1"
     tfc_org    = "shaikhniraj"
}

generate "cloud" {

    path = "cloud.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
    terraform {
        required_version = ">=1.9.0"

        cloud {
            organization = "${local.tfc_org}"

            workspaces {
                name = "streamingapp-${replace(replace(path_relative_to_include(), "/", "-"), "\\", "-")}"
            }
        }
    }
    EOF
}

generate "provider" {

path = "provider.tf"
if_exists = "overwrite_terragrunt"
contents = <<EOF
provider "aws" { 
    region = "${local.aws_region}"
}
EOF

}