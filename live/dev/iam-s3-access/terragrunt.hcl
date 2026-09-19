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

# Placeholder used ONLY during plan/init/validate, when the real s3 output
  # might not be resolvable yet (e.g. during run --all's early discovery pass).
  # apply is deliberately excluded — it always requires the real value.
  mock_outputs = {
    bucket_arn = "arn:aws:s3:::mock-bucket-for-planning-only"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]

}

inputs = {
  project     = "streamingapp"
  environment = "dev"
  bucket_arn  = dependency.s3.outputs.bucket_arn
}