# ADR-008: CI/CD Pipeline Security Hardening Strategy

## Status
Accepted

## Date
2026-04-13

## Context
Phase 3 required hardening the GitHub Actions pipeline against supply chain attacks,
secret exposure, and insecure container deployment. The pipeline previously used
floating action tags (@v4, @master) with no secret scanning or policy enforcement.

## Decision
1. Pin all GitHub Actions to immutable SHA hashes.
2. Add Semgrep SAST with OWASP Top 10, Python, and secrets rulesets.
3. Add Gitleaks for full git history secret scanning with fetch-depth: 0.
4. Add OPA/Rego policy gate blocking containers that run as root.

## Rationale
Floating tags are mutable — a compromised upstream repo can silently replace
tag contents. SHA pinning makes each action reference immutable and tamper-evident.
Dual secret scanning (GHAS + Gitleaks) provides two independent detection engines.
OPA enforces container security policy as code — version-controlled and automated.

## Consequences
- Pipeline is protected against supply chain substitution attacks.
- Secret exposure to production is blocked at the pipeline level.
- Root container deployments are blocked by automated policy enforcement.
- All action SHAs must be manually updated when upgrading versions.

## Tests
- All 5 action references verified as SHA hashes.
- Gitleaks confirmed detecting AWS credential patterns.
- Repo confirmed clean across 63 commits.
- OPA confirmed denying root, allowing UID 1001.
