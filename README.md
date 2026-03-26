# Cloud Security Masterclass — Phase 1: Docker Hardening

A hands-on cloud security engineering project built on a production-grade
FastAPI backend. This repo documents a structured, phase-by-phase journey
from backend developer to Cloud Security Engineer — with every decision
logged, every vulnerability scanned, and every security control tested.

Built on a dual-path strategy: AWS Cloud Engineering and Cloud Security
run in parallel until the deeper specialization becomes clear. Both paths
share the same foundation — Docker, CI/CD, AWS, and IaC — so nothing
built here is wasted regardless of direction.

---

## Stack

| Layer | Technology |
|---|---|
| API | FastAPI (Python) |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Auth | JWT |
| Containers | Docker + Docker Compose |
| Scanning | Trivy (CVE analysis) |
| Testing | Pytest |

---

## Phase 1 — Docker Hardening (Current)

### Completed
- Multi-stage Dockerfile with minimal runtime image
- Non-root user enforcement inside containers
- Health checks on all services
- Secrets removed from image layers — all credentials via environment variables
- Redis password authentication enabled
- `.env.example` provided for safe onboarding; `.env` excluded from version control
- Trivy CVE scanning across all three images (FastAPI app, postgres:16-alpine, redis:7-alpine)
- CVE triage performed — critical findings remediated (including CVE-2025-8869 pip vulnerability)

### In Progress
- ADR (Architecture Decision Record) for Docker hardening decisions
- TDD checkpoint: proving security features work and attacks fail

---

## Getting Started

### Prerequisites
- Docker Desktop
- Docker Compose

### Run Locally
```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO

# Set up environment
cp .env.example .env
# Edit .env with your values

# Build and start all services
docker compose up --build
```

The API will be available at `http://localhost:8000`.

---

## Security Posture

This project treats security as a first-class concern, not an afterthought:

- **Container hardening** — non-root execution, minimal base images, no secrets baked in
- **CVE management** — Trivy scans on every image, critical/high findings triaged and remediated
- **Secrets hygiene** — environment variable injection only, `.env` gitignored
- **TDD for security** — tests written to verify controls work *and* confirm attacks fail

---

## Roadmap

Both paths share the same phases. The deeper specialization gets chosen
when the foundation is solid and a personal direction becomes clear.

| Phase | Focus | AWS Cloud Path | Security Path | Status |
|---|---|---|---|---|
| 1 | Docker Hardening | Container best practices | CVE scanning, secrets hygiene | 🔄 In Progress |
| 2 | CI/CD Security | Automated builds, deploy pipelines | SAST, secrets scanning in CI | Upcoming |
| 3 | AWS Fundamentals + IAM | EC2, S3, RDS, VPC | IAM least privilege, SCPs, GuardDuty | Upcoming |
| 4 | Infrastructure as Code | Terraform / CloudFormation | IaC security scanning, drift detection | Upcoming |
| 5 | Threat Modeling & Incident Response | Observability, alerting | Attack surface mapping, IR playbooks | Upcoming |
| 6 | Capstone + Job Application Sprint | Deploy production-grade app | Security audit of full stack | Upcoming |

---

## Certifications

| Cert | Target | Purpose |
|---|---|---|
| AWS Cloud Practitioner (CLF-C02) | May 2026 | Foundation for both paths |
| AWS Security Specialty or CompTIA Security+/CySA+ | Post-employment | Deepen chosen specialization |

---

## Author

Backend developer transitioning into Cloud Security Engineering.
Background in music engineering — signal integrity, gain staging, and
noise floor management turned out to be surprisingly good preparation
for thinking about network integrity, access control, and threat detection.

> *"I've been engineering secure, fault-tolerant systems since before
> I wrote my first line of Python. The domain changed. The discipline didn't."*
