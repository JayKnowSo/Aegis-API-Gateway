# ADR-007: CloudTrail Audit Logging + Root Account Detective Control

## Status
Accepted

## Date
2026-04-04

## Context
Phase 2 of the Cloud Security Masterclass requires audit logging across the AWS account.
Without CloudTrail, there is no forensic record of API activity. If credentials are
compromised, there is no way to determine what was accessed, by whom, or when.
The root account represents the highest-privilege identity in the account. Any usage
of root outside of break-glass scenarios is a security signal that warrants immediate
investigation.

## Decision
1. Enable CloudTrail with a multi-region trail and log file validation.
2. Stream CloudTrail logs to CloudWatch Logs for real-time detection.
3. Create a metric filter that counts any root account API call.
4. Create a CloudWatch alarm that fires within 5 minutes of any root usage.

## Rationale
- Multi-region: catches activity in all AWS regions, not just us-east-1.
- Log file validation: enables tamper detection using digest files. Required for
  compliance and incident response chain of custody.
- Root alarm: root credentials should never be used in normal operations. A single
  root API call is an anomaly. The alarm converts a passive log into an active
  detective control. This pattern is required by CIS AWS Foundations Benchmark 1.7.

## Consequences
- All API calls across all regions are now logged.
- Root account usage triggers a CloudWatch alarm within one evaluation period (5 min).
- Log delivery adds minor latency (~5-15 min to S3, near-real-time to CloudWatch).
- Monthly cost: within AWS free tier for low-volume accounts.

## Tests
5 CLI tests documented in Phase 2 Day 5 proof:
1. Trail exists, multi-region enabled, log validation enabled.
2. IsLogging = true.
3. CloudWatch log group exists.
4. Metric filter targeting root usage exists.
5. Alarm configured with threshold = 1, period = 300s.
