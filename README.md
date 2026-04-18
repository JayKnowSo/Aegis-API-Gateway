# Aegis API Gateway

> A production-grade cloud security engineering portfolio — built phase by phase, hardened layer by layer.

[![CI Pipeline](https://img.shields.io/github/actions/workflow/status/JayKnowSo/aegis-api-gateway/ci.yml?label=CI%20Pipeline&style=flat-square)](https://github.com/JayKnowSo/aegis-api-gateway/actions)
[![Tests](https://img.shields.io/badge/tests-57%20passing-brightgreen?style=flat-square)]()
[![CVEs](https://img.shields.io/badge/critical%20CVEs-0-brightgreen?style=flat-square)]()
[![Checkov](https://img.shields.io/badge/checkov-32%2F32-brightgreen?style=flat-square)]()
[![ADRs](https://img.shields.io/badge/ADRs-12-blue?style=flat-square)]()
[![Phases](https://img.shields.io/badge/phases-6%2F6-blue?style=flat-square)]()

---

## What This Is

Aegis is a FastAPI service hardened across six sequential security engineering phases — from container security to infrastructure as code. Every decision is documented, every control is tested, and every pipeline gate is enforced automatically.

This is not a tutorial project. It is a demonstration of how security is built into a system from day one.

---

## Security Posture at a Glance

| Control Area | Implementation | Status |
|---|---|---|
| Container Hardening | Multi-stage build, non-root UID 1001, health checks, digest pinning | ✅ |
| Secrets Management | `.env` injection, Redis auth, no secrets in image layers | ✅ |
| IAM Least Privilege | Custom policies, NotPrincipal deny, EC2 instance role | ✅ |
| Audit Logging | CloudTrail multi-region trail, CloudWatch alerts, root usage alarm | ✅ |
| SAST | Semgrep (p/python, p/secrets, p/owasp-top-ten) | ✅ |
| Secret Scanning | Gitleaks — 63 commits clean | ✅ |
| SBOM | Syft CycloneDX — 510 components inventoried | ✅ |
| Dependency Scan | Grype — 0 CRITICAL findings | ✅ |
| Image Signing | Cosign sign-blob (tarball), keypair committed | ✅ |
| Policy Enforcement | OPA/Rego gate — blocks non-root containers at CI | ✅ |
| DAST | OWASP ZAP baseline — 0 failures, 65 passes | ✅ |
| IaC Security | Terraform + Checkov 32/32, pre-commit hook, blocking CI gate | ✅ |
| Attack Surface | Idempotent hashing, bcrypt 4.3.0 pinned, input hardening | ✅ |
| Middleware | RBAC + CSP headers enforced at request layer | ✅ |

---

## CI/CD Pipeline

Every push triggers a fully automated security pipeline. No manual gates.
test → sast → sbom → dast → trivy-scan

| Job | Tools | Gate Type |
|---|---|---|
| `test` | pytest — 57 tests | Blocking |
| `sast` | Semgrep, Gitleaks, OPA/Rego | Blocking |
| `sbom` | Syft (CycloneDX), Grype, Cosign | Blocking |
| `dast` | OWASP ZAP baseline | Blocking |
| `trivy-scan` | Trivy image CVE scan | Blocking |

All 5 GitHub Actions are SHA-pinned to immutable commit hashes — no floating tags, no supply chain drift.

---

## Architecture
┌─────────────────────────────────────────┐
│              GitHub Actions             │
│   test → sast → sbom → dast → trivy    │
└────────────────┬────────────────────────┘
│
┌────────────────▼────────────────────────┐
│           FastAPI Application           │
│  RBAC middleware │ CSP headers          │
│  bcrypt auth     │ idempotent hashing   │
└───────┬──────────────────────┬──────────┘
│                      │
┌───────▼──────┐      ┌────────▼─────────┐
│  PostgreSQL  │      │  Redis            │
│  (app data)  │      │  (auth + cache)   │
└──────────────┘      └──────────────────┘
┌─────────────────────────────────────────┐
│              AWS Infrastructure         │
│  S3 (encrypted, versioned, logged)      │
│  IAM least-privilege roles + policies   │
│  CloudTrail multi-region audit trail    │
│  CloudWatch metrics + root usage alarm  │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│         Terraform (IaC)                 │
│  Checkov 32/32  │  pre-commit hook      │
│  Blocking CI gate │ audit-ready state   │
└─────────────────────────────────────────┘

---

## Six-Phase Build

### Phase 1 — Container Security
Multi-stage Dockerfile, non-root user (UID 1001), health checks, Redis password auth, image digest pinning, Trivy CVE scanning.

### Phase 2 — AWS IAM Hardening
Least-privilege IAM users, custom S3-readonly policy, EC2 instance role, S3 Block Public Access + NotPrincipal deny, CloudTrail multi-region trail, CloudWatch log streaming, root account usage alarm.

### Phase 3 — CI/CD Supply Chain Security
SHA-pinned actions, Semgrep SAST, Gitleaks secret scanning, Syft SBOM (510 components, CycloneDX), Grype vulnerability scan, Cosign image signing, OPA/Rego policy gate, OWASP ZAP DAST.

### Phase 4 — Infrastructure as Code
Terraform S3 module (encryption, versioning, logging, public access block), Checkov 32/32 passing, pre-commit hook, blocking CI gate. Infrastructure is reproducible and audit-ready.

### Phase 5 — Threat Modeling & Hardening
Idempotent hashing for attack surface reduction, bcrypt 4.3.0 pinned, runtime stability hardened as prerequisite for production monitoring. Common attack vectors mitigated at the code layer.

### Phase 6 — Portfolio Launch
57 passing tests. 12 Architecture Decision Records. Zero critical CVEs. Six phases documented.

---

## Architecture Decision Records

| ADR | Decision |
|---|---|
| ADR-001 | Multistage Docker Build Strategy |
| ADR-002 | Container Vulnerability Assessment |
| ADR-003 | Third-Party Image CVE Assessment |
| ADR-004 | CI/CD Security Pipeline Design |
| ADR-005 | IAM Hardening Strategy |
| ADR-006 | IAM Roles and Trust Policies |
| ADR-007 | CloudTrail Detective Controls |
| ADR-008 | CI/CD Hardening Strategy |
| ADR-009 | Supply Chain Security (SBOM + Cosign) |
| ADR-010 | DAST Integration |
| ADR-011 | IaC Governance (Terraform + Checkov) |
| ADR-012 | Threat Hardening — Idempotent Hashing + Bcrypt Pin |

---

## Stack

| Layer | Technology |
|---|---|
| API | FastAPI (Python) |
| Database | PostgreSQL |
| Cache / Auth | Redis |
| Infrastructure | AWS (S3, IAM, CloudTrail, CloudWatch) |
| IaC | Terraform + Checkov |
| Container | Docker (multi-stage, hardened) |
| CI/CD | GitHub Actions (SHA-pinned) |
| SAST | Semgrep |
| Secret Scan | Gitleaks |
| SBOM | Syft (CycloneDX) |
| Dependency Scan | Grype |
| Image Signing | Cosign |
| Policy | OPA / Rego |
| DAST | OWASP ZAP |
| CVE Scan | Trivy |

---

## Running Locally

**Prerequisites:** Docker, Docker Compose, Python 3.11+

```bash
git clone https://github.com/JayKnowSo/aegis-api-gateway.git
cd aegis-api-gateway
cp .env.example .env
docker compose up -d
pytest tests/ -v
```

---

## Running the Security Pipeline Locally

```bash
semgrep --config=p/python --config=p/secrets .
gitleaks detect --source . -v
syft . -o cyclonedx-json > sbom.json
grype sbom:sbom.json
trivy image aegis-api-gateway:latest
checkov -d terraform/
```

---

## Security Contact

Found a vulnerability? Open a GitHub Issue with the label `security`.

---

*Built by Jemel Padilla — Cloud Security Engineer*
*Orlando, FL · [github.com/JayKnowSo](https://github.com/JayKnowSo)*
