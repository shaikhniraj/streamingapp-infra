 #A dedicated, narrowly-scoped IAM user for the running app to authenticate..
resource "aws_iam_user" "app" {
  name = "${var.project}-${var.environment}-s3-access"
}

# The actual key pair the app will use. Terraform generates both halves;
# the secret half is only ever retrievable via the output below.
resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

# The permission policy — deliberately narrow: read/write/delete objects
# INSIDE the bucket, and list the bucket. Nothing else, no other service,
# no other bucket.
resource "aws_iam_user_policy" "app_s3_access" {
  name = "${var.project}-${var.environment}-s3-policy"
  user = aws_iam_user.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ObjectReadWrite"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        # "/*" — this rule applies to OBJECTS inside the bucket, not the bucket itself
        Resource = "${var.bucket_arn}/*"
      },
      {
        Sid      = "BucketList"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        # No "/*" here — ListBucket is a bucket-level action, targeting the bucket ARN itself
        Resource = var.bucket_arn
      }
    ]
  })
}