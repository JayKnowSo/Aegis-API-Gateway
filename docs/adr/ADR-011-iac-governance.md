# ADR-011: Infrastructure as Code (IaC) Toolchain and Governance

## Status
Accepted (April 2026)

## Context
As the Custom_Greeting_App scales, manual provisioning of AWS resources (S3, KMS, IAM) creates "configuration drift" and security inconsistencies. We required a method to ensure infrastructure is versionable, repeatable, and inherently secure before deployment. 

A critical challenge was "Brownfield" reconciliation: bringing existing Phase 2 manual assets and early Phase 4 experimental resources under strict state management without causing resource destruction or service interruption.

## Decision
Standardize on **Terraform** for infrastructure provisioning and **Checkov** for static analysis security (SAST) of IaC.

1.  **State Management:** Utilize Terraform's state engine to maintain a single source of truth for cloud resources.
2.  **State Reconciliation:** Implement a strict `terraform import` workflow for all pre-existing assets to ensure code/cloud alignment.
3.  **Security Gates:** Integrate Checkov as a blocking pre-commit hook and CI/CD stage to enforce encryption-at-rest (AES256/KMS) and Public Access Block (PAB) policies.
4.  **Resource Modularization:** Group security-related resources (like S3 buckets and their associated Versioning/Encryption/PAB blocks) to ensure no resource is "naked" in the cloud.

## Rationale
- **Idempotency:** Terraform ensures that running the same code multiple times results in the same cloud state, eliminating manual error.
- **Shift-Left Security:** By using Checkov, security vulnerabilities (like unencrypted buckets) are caught in the IDE/Pipeline, before a single API call is made to AWS.
- **Provider Maturity:** The AWS Provider for Terraform offers the most granular control over security-sensitive resources like IAM and KMS.

## Consequences
- **Zero-Tolerance for Drift:** Any manual change in the AWS Console will be flagged as drift during the next `terraform plan`.
- **Import Overhead:** New existing resources must be imported into the state file before management, requiring high discipline during migrations.
- **Immutable Infrastructure:** Infrastructure is no longer patched; it is redeployed via code, ensuring a clean audit trail in GitHub.

## Compliance Check (Phase 4 Standards)
- [x] All S3 buckets must have `aws_s3_bucket_public_access_block`.
- [x] All S3 buckets must have `aws_s3_bucket_server_side_encryption_configuration`.
- [x] Plan must result in "0 to destroy" before any production apply.
