terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# -----------------------
# S3 BUCKETS
# -----------------------
resource "aws_s3_bucket" "app_assets" {
  #checkov:skip=CKV_AWS_144:cross-region replication not required in lab environment
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required in lab environment
  bucket        = "jayknowso-tf-app-assets-2026"
  force_destroy = true
}

resource "aws_s3_bucket" "log_bucket" {
  #checkov:skip=CKV_AWS_144:cross-region replication not required in lab environment
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required in lab environment
  bucket        = "jayknowso-logs-2026"
  force_destroy = true
}

# -----------------------
# KMS ENCRYPTION
# -----------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

# -----------------------
# VERSIONING
# -----------------------
resource "aws_s3_bucket_versioning" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------
# KMS KEY
# -----------------------
resource "aws_kms_key" "s3_key" {
  description         = "KMS key for S3 encryption"
  enable_key_rotation = true
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

# -----------------------
# LIFECYCLE (CKV2_AWS_61 + CKV_AWS_300)
# -----------------------
resource "aws_s3_bucket_lifecycle_configuration" "app_assets" {
  bucket = aws_s3_bucket.app_assets.id
  rule {
    id     = "app-retention"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    id     = "log-retention"
    status = "Enabled"
    filter {}
    expiration {
      days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# -----------------------
# PUBLIC ACCESS BLOCK
# -----------------------
resource "aws_s3_bucket_public_access_block" "app_assets" {
  bucket                  = aws_s3_bucket.app_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------
# LOGGING
# -----------------------
resource "aws_s3_bucket_logging" "app_assets_logging" {
  bucket        = aws_s3_bucket.app_assets.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# --- SecureAI Deployment Infrastructure ---

# 1. IAM Role for SecureAI (Least Privilege)
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

# 2. SSM Parameter for SecureAI API Key
resource "aws_ssm_parameter" "anthropic_key" {
  name        = "/secureai/dev/anthropic_api_key"
  description = "Secret key for SecureAI Anthropic calls"
  type        = "SecureString"
  key_id      = aws_kms_key.s3_key.arn
  value       = "REPLACE_ME_IN_AWS_CONSOLE" # Security: Never put keys in Git

  tags = {
    Project = "secureai-platform"
  }
}

# 3. Policy to allow SecureAI to only read its own secret
resource "aws_iam_policy" "secureai_policy" {
  name = "secureai-least-privilege"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "ssm:GetParameter"
      Effect   = "Allow"
      Resource = aws_ssm_parameter.anthropic_key.arn
    }]
  })
}

# 4. Attach policy to role
resource "aws_iam_role_policy_attachment" "secureai_attach" {
  role       = aws_iam_role.secureai_role.name
  policy_arn = aws_iam_policy.secureai_policy.arn
}
