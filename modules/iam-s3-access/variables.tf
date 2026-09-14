variable "project" {
  type = string
}
variable "environment" {
  type = string
}
variable "bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket this user is scoped to access — passed in from the s3 component's output"
}