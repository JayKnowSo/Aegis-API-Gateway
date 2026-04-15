data "aws_caller_identity" "current" {}

# 1. THE DATA BUCKET
resource "aws_s3_bucket" "app_assets" {
  bucket        = "jayknowso-tf-app-assets-2026"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "app_assets_versioning" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "app_assets_pab" {
  bucket = aws_s3_bucket.app_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "app_assets_logging" {
  bucket        = aws_s3_bucket.app_assets.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# 2. THE LOG BUCKET (Hardened)
resource "aws_s3_bucket" "log_bucket" {
  bucket        = "jayknowso-logs-2026"
  force_destroy = true
}

# Fix CKV_AWS_21 for log_bucket
resource "aws_s3_bucket_versioning" "log_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration { status = "Enabled" }
}

# Fix CKV2_AWS_6 for log_bucket
resource "aws_s3_bucket_public_access_block" "log_pab" {
  bucket = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Fix CKV2_AWS_61 for both buckets
resource "aws_s3_bucket_lifecycle_configuration" "shared_lifecycle" {
  for_each = toset([aws_s3_bucket.app_assets.id, aws_s3_bucket.log_bucket.id])
  bucket   = each.value

  rule {
    id     = "cleanup"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
    expiration { days = 90 }
  }
}

# 3. ENCRYPTION (KMS)
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 encryption"
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

# Fix CKV_AWS_145 for both buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  for_each = toset([aws_s3_bucket.app_assets.id, aws_s3_bucket.log_bucket.id])
  bucket   = each.value

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
