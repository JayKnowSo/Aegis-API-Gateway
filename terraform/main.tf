# 1. KMS Key for Encryption
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# 2. Application Assets Bucket
resource "aws_s3_bucket" "app_assets" {
  #checkov:skip=CKV_AWS_144:cross-region replication not required in lab environment
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required in lab environment
  bucket = "jayknowso-tf-app-assets-2026"

  tags = {
    Name        = "jayknowso-tf-app-assets-2026"
    Environment = "dev"
    Project     = "aegis-api-gateway"
    ManagedBy   = "terraform"
  }
}

# 3. Logging Bucket
resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_144:cross-region replication not required in lab environment
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required in lab environment
  bucket = "jayknowso-logs-2026"

  tags = {
    Name        = "jayknowso-logs-2026"
    Environment = "dev"
    Project     = "aegis-api-gateway"
    ManagedBy   = "terraform"
  }
}

# 4. Versioning
resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 5. KMS Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

# 6. Public Access Block
resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket                  = aws_s3_bucket.app_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 7. Access Logging (app_assets → logs bucket)
resource "aws_s3_bucket_logging" "app_assets" {
  bucket        = aws_s3_bucket.app_assets.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/"
}

# 8. Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  rule {
    id     = "app-retention"
    status = "Enabled"
    filter {}
    expiration {
      days = 90
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "log-retention"
    status = "Enabled"
    filter {}
    expiration {
      days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# --- SecureAI Platform Infrastructure ---

# 1. SecureAI Identity (Least Privilege)
resource "aws_iam_role" "secureai_role" {
  name = "jayknowso-secureai-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# 2. SecureAI Secret (KMS-encrypted)
resource "aws_ssm_parameter" "anthropic_key" {
  name        = "/secureai/dev/anthropic_api_key"
  description = "Anthropic API Key for SecureAI"
  type        = "SecureString"
  key_id      = aws_kms_key.s3_key.arn
  value       = "REPLACE_ME_IN_CONSOLE"

  tags = {
    Project = "secureai"
  }
}

# 3. Policy: Allow SecureAI to only read THIS specific secret
resource "aws_iam_role_policy" "secureai_ssm_policy" {
  name = "secureai-ssm-access"
  role = aws_iam_role.secureai_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ssm:GetParameter"
        Effect   = "Allow"
        Resource = aws_ssm_parameter.anthropic_key.arn
      },
      {
        Action   = "kms:Decrypt"
        Effect   = "Allow"
        Resource = aws_kms_key.s3_key.arn
      }
    ]
  })
}
