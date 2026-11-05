# Contributing guide

## Git workflow

- Main branch `main` is always deployable; work in short branches `feature/US-123-short-title`, `fix/…`, `chore/…`.
- One **Pull Request** per user story (or independent part of a story), reviewed by at least one person, with green CI.
- Rebase or squash before merging to keep a readable history.

## Commit messages (Conventional Commits)

`type(scope): summary in the imperative`, with types `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`.
Example: `feat(order): publish an event after creation (US-004)`.

## Before opening a PR

1. The story meets the [Definition of Ready](docs/agile/definition-of-ready.md) and the PR the [Definition of Done](docs/agile/definition-of-done.md).
2. `mvn -B verify` passes; `npx ng build` passes if the front is touched.
3. Any notable architecture decision is recorded in an ADR (`docs/adr/`, next number).
4. Contracts between services (REST APIs, Kafka events) change in a backward-compatible way, or are versioned.

## Architecture rules

- One service = its data: no direct access to another service's database.
- Synchronous communication through the gateway/REST, asynchronous through Kafka; idempotent consumers.
- No secret value in the repository.
