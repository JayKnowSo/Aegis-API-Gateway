ADR-005: IAM Hardening Strategy
Date: 2026-03-26
Status: Accepted
Author: Jemel Padilla
Project: custom-greeting-app

Context
The custom-greeting-app AWS infrastructure requires programmatic and console access for management, deployment, and automation. The default AWS root account provides unrestricted access but represents an unacceptable security risk as a daily working identity.

Decision
We implement a layered IAM hardening strategy with three core principles:

1. Root account is emergency-only
The root account has no access keys. MFA is enforced via FIDO2 passkey. Root is never used for daily operations, CLI access, or automation. This satisfies CIS AWS Foundations Benchmark controls 1.4 and 1.5.

2. Named IAM users for human identities
A dedicated IAM admin user (jayknowso-admin) with AdministratorAccess and FIDO2 MFA handles all infrastructure work. This creates an auditable, named identity separate from root. All API calls are attributable to a specific identity in CloudTrail.

3. Least privilege for service identities
Non-admin identities (e.g. jayknowso-dev) receive only the minimum permissions required for their function. Custom IAM policies are written in JSON and scoped to specific actions and resources rather than using broad AWS managed policies.

Example — jayknowso-s3-readonly:
json{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::*",
        "arn:aws:s3:::*/*"
      ]
    }
  ]
}
Least privilege was verified via CLI — the dev identity was explicitly denied EC2 access confirming the policy boundary holds.

Alternatives Considered
OptionRejected BecauseUse root for all operationsSingle point of compromise. No audit trail. Violates every cloud security standard.Use AdministratorAccess for all usersNo blast radius containment. A compromised dev credential = full account access.Use AWS managed policies for dev identitiesToo broad. AWS managed policies grant more permissions than needed. Custom policies are explicit and auditable.

Consequences
Positive:

Root exposure eliminated from daily operations
Every API call is attributable to a named identity
Blast radius of a compromised dev credential is limited to S3 read operations
Policy decisions are documented, version-controlled, and auditable

Negative:

Custom policies require maintenance as service needs evolve
More upfront work than attaching managed policies


Music Engineering Parallel
This is gain staging applied to access control. You don't send a full signal through every channel. Each identity gets exactly the signal level it needs to do its job. Anything above that is noise — and in security, noise is attack surface.
