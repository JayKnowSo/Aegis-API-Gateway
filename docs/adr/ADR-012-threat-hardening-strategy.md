# ADR-012: Threat Hardening Strategy — Idempotent Hashing and Bcrypt Pinning

**Date:** 2026-04-18
**Status:** Accepted
**Phase:** 5 — Threat Modeling & Security Hardening

---

## Context

With infrastructure controls in place across Phases 1–4, Phase 5 focused on application-layer attack surface reduction. Two specific vulnerabilities were identified for remediation:

1. **Non-idempotent write operations** — repeated identical requests could produce duplicate database records, creating a vector for resource exhaustion and data integrity attacks.
2. **Unpinned bcrypt dependency** — floating version resolution left the authentication layer exposed to supply chain drift, where a bcrypt minor or patch release could silently alter hashing behavior or introduce regressions.

Both issues were flagged during internal threat review against OWASP API Security Top 10 (API4: Unrestricted Resource Consumption, API8: Security Misconfiguration).

---

## Decision

### Idempotent Hashing

Implemented deterministic idempotency keys derived from request payload content. Duplicate requests within a defined window are detected at the application layer before any database write is attempted. This eliminates the duplicate-write attack vector without requiring external state management.

### Bcrypt Version Pin

Pinned `bcrypt==4.3.0` in `requirements.txt`. This locks the authentication hashing library to a known-good, audited version. Any future upgrade requires an explicit, reviewed dependency bump — not silent resolution.

---

## Alternatives Considered

| Option | Reason Rejected |
|---|---|
| Database unique constraints only | Catches duplicates after write — does not eliminate the round-trip cost or the resource consumption risk |
| Redis-based idempotency store | Adds external state dependency; overkill for current traffic profile |
| Unpinned bcrypt (latest) | Acceptable in development; unacceptable in a security-hardened pipeline where dependency drift is a threat vector |
| Argon2 instead of bcrypt | Valid alternative, but bcrypt is already integrated and audited; switching introduces migration risk without proportional gain at this stage |

---

## Consequences

- Duplicate write attacks are mitigated at the application layer
- bcrypt behavior is deterministic and auditable across all environments
- `requirements.txt` now constitutes a pinned, reviewable dependency manifest
- Any bcrypt upgrade triggers a deliberate code review cycle
- 57/57 tests pass under the hardened configuration, confirming no regression

---

## Related ADRs

- ADR-002: Container Vulnerability Assessment
- ADR-005: IAM Hardening Strategy
- ADR-009: Supply Chain Security
