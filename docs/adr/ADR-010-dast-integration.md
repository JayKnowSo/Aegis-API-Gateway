# ADR-010: DAST Integration — OWASP ZAP Baseline Scan

## Status
Accepted

## Date
2026-04-13

## Context
Static analysis (Semgrep) validates code logic before the application runs.
It cannot detect vulnerabilities that only appear at runtime — missing security
headers, authentication bypass, or insecure API behavior. A DAST tool is required
to test the running application.

## Decision
Integrate OWASP ZAP baseline scan into the pipeline. The application stack is
started inside the GitHub Actions runner, ZAP scans it via HTTP, and the HTML
report is uploaded as a pipeline artifact.

## Rationale
ZAP baseline scan is passive — it probes without exploiting, making it safe for
CI/CD. The -I flag means warnings are reported but do not block the pipeline.
Only new FAIL findings block shipping. This threshold balances security signal
with pipeline stability.

## Consequences
- Every push tests the running application against 65+ OWASP security checks.
- Pipeline runtime increases by approximately 3-5 minutes for ZAP scan.
- Two warnings identified: missing Anti-clickjacking and CORP headers.
  These will be remediated in Phase 6 FastAPI middleware update.
- ZAP HTML report provides per-commit audit trail of runtime security posture.

## Tests
- Local scan result: 0 FAIL, 2 WARN, 65 PASS.
- Pipeline confirmed green on run #22.
