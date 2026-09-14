resource "aws_s3_bucket" "media" {
    bucket = "${var.project}-${var.environment}-media-${data.aws_caller_identity.current.account_id}"
     # appending the account ID guarantees uniqueness without you having to guess a free name

tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Fetches your current AWS account ID at apply time, used above for uniqueness
data "aws_caller_identity" "current" {}

# Explicitly blocks all forms of public access — belt-and-suspenders even
# though we never grant a public policy below. Best practice for any bucket
# holding app data that should only be reached via presigned URLs.
resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allows the browser to make direct PUT/GET requests to S3 (via presigned URLs)
# from your frontend's origin — without this, browsers block the request due
# to CORS even though the presigned URL itself is valid
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]  # tighten this to your actual frontend URL once you have one (Ingress step)
    max_age_seconds = 3000
  }
}