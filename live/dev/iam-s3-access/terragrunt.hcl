include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/iam-s3-access"
}

# Reads outputs from the already-applied s3 component instead of us
# hardcoding the bucket ARN by hand
dependency "s3" {
  config_path = "../s3"
}

inputs = {
  project     = "streamingapp"
  environment = "dev"
  bucket_arn  = dependency.s3.outputs.bucket_arn
}