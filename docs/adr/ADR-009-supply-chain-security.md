# ADR-009: Supply Chain Security — SBOM + Cosign

## Status
Accepted

## Date
2026-04-13

## Context
EO 14028 and CISA guidance require software producers to generate and maintain
a Software Bill of Materials. Container images have no provenance verification
by default — there is no way to confirm an image came from a specific pipeline
and was not tampered with after build.

## Decision
1. Generate CycloneDX SBOM on every push using Syft.
2. Scan SBOM against live CVE feeds using Grype, fail on CRITICAL.
3. Sign image tarball using Cosign sign-blob with a keypair stored in GitHub Secrets.

## Rationale
SBOM generation provides a complete inventory of 510 components for audit and
compliance purposes. Grype cross-references against NVD and GitHub Advisory DB
automatically. Cosign sign-blob was chosen over registry-based signing because
Phase 3 has no container registry — images are built and scanned locally.
Phase 4 will upgrade to full registry-based signing with transparency log.

## Consequences
- Every push produces a downloadable CycloneDX SBOM artifact.
- CRITICAL CVEs in any of 510 components will block the pipeline.
- Image tarball is cryptographically signed — tampering is detectable.
- Cosign private key must be rotated if compromised.

## Tests
- SBOM generated: 510 components cataloged.
- Grype scan: 0 CRITICAL, 19 High, 37 Medium, 15 Low.
- Cosign signing confirmed in pipeline run #21.
