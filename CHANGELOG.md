# Changelog

## v0.2.0 — English edition

### Changed
- Skill instructions, reference guides, generator messages, ADRs, generated documentation, UI text and code comments are now in English.
- Generated paths are now English: `docs/product/`, `docs/quality/test-strategy.md`, `docs/product/risks.md`, and `docs/architecture/00-overview.md` through `06-security.md`.

### Security
- Docker Compose ports are published on `127.0.0.1` only.
- The Java Dockerfile no longer uses `rm -rf`.
- Removed the Keycloak Compose healthcheck based on `/dev/tcp`; no service depended on it.

### Added
- `LICENSE` inside the skill folder.

## v0.1.0 — French edition

Initial release.
