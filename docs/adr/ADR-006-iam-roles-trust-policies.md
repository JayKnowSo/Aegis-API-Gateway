# ADR-006: IAM Roles and Trust Policies for Service Identities

**Date:** 2026-03-27
**Status:** Accepted
**Author:** Jemel Padilla
**Project:** Custom_Greeting_App

## Context

AWS services like EC2 and Lambda need permissions to interact with other AWS resources. Using IAM users with long-lived access keys for service identities creates permanent credential exposure risk. A more secure pattern is required.

## Decision

All service identities use IAM roles instead of IAM users. Roles issue temporary credentials via AWS STS that expire automatically. No long-lived access keys are stored on any compute resource.

**Role created:** `jayknowso-ec2-s3-readonly`

**Trust policy scoped to EC2 only:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Permissions:** AmazonS3ReadOnlyAccess — scoped to S3 read operations only.

**Verified via:** sts:AssumeRole from CloudShell — temporary credentials issued with automatic expiration. S3 access confirmed. Trust policy restored after testing — no permanent test permissions left in policy.

## Alternatives Considered

- IAM user access keys on EC2 — rejected. Long-lived credentials. If instance is compromised, keys are permanently exposed.
- Hardcoded credentials in code — rejected. Critical vulnerability. Automatic disqualifier in any security audit.
- Overly broad role permissions — rejected. Violates least privilege. Role scoped to S3 read only.

## Consequences

**Positive:**
- Zero long-lived credentials on any compute resource
- Temporary credentials auto-rotate via AWS STS
- Blast radius of compromised instance limited to S3 read
- Trust policy explicitly scopes which services can assume the role
- Test permissions cleaned up immediately after verification

**Negative:**
- Roles require more upfront design than access keys
- Trust policies must be maintained as architecture evolves

## Music Engineering Parallel

A role is a session pass — scoped, temporary, expires when the session ends. An IAM user is a permanent keycard. You don't give session musicians permanent building access. You give them exactly what they need for exactly as long as they need it. When the session ends, access ends.
