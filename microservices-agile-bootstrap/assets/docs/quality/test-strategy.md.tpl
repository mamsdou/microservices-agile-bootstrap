# Test strategy

## Pyramid

| Level | Tool | Scope | Frequency |
|---|---|---|---|
| Unit | JUnit 5, Mockito, AssertJ | Service/domain logic, no network or database | Every commit (CI) |
| Integration | Spring Boot Test + Testcontainers (PostgreSQL, Kafka) | Persistence, Flyway migrations, event production/consumption | Every PR |
| Contract | Spring Cloud Contract or Pact | REST APIs and event schemas between services | Every PR touching a contract |
| End to end | Cypress/Playwright on the Compose stack | Critical UI journeys | Before release |

The skeleton provides unit and security tests per service; higher levels are backlog enablement stories.

## Rules

- Test behavior (acceptance criteria), not implementation.
- Tests are independent, deterministic and fast; no dependency on execution order.
- No call to another real service in a unit test.
- A fixed bug = a test that would have caught it.

## Test environments

Integration tests use ephemeral containers (Testcontainers): no shared database. Datasets are created by the test itself.

## Indicative thresholds

Line coverage ≥ 70% on business logic (an indicator, not a goal in itself); zero ignored test without an associated ticket.
