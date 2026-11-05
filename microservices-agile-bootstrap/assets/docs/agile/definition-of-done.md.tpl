# Definition of Done (DoD)

A backlog item is "Done" only if **all** of the following are true. The DoD is shared by the team and applies to every increment.

## Code
- [ ] Code reviewed (Pull Request approved by at least one other person).
- [ ] Follows the architecture rules in `CONTRIBUTING.md` (one service = its data, backward-compatible contracts).
- [ ] No critical static analysis alert; no secret in the repository.

## Tests
- [ ] Unit tests added/updated and passing (`mvn -B verify`).
- [ ] Integration tests for new contracts (REST, Kafka) where relevant.
- [ ] Story acceptance criteria verified, automatically or by someone other than the author.
- [ ] Front build OK (`ng build`) if the front is touched.

## Delivery
- [ ] CI pipeline green on the branch.
- [ ] Deployable: the Docker image builds and the stack starts (`docker compose up`).
- [ ] Flyway migrations added if the schema changes (an applied migration is never modified).
- [ ] Usable logs in Kibana for the new behavior.

## Documentation
- [ ] ADR created if an architecture decision was made.
- [ ] `docs/` updated (API contracts, events, schema) and README up to date.
- [ ] Story can be demonstrated at the sprint review.
