# 03 — Data

## Principle: one database per service

A single PostgreSQL 16 instance in development, but **one logical database per service**; in production, each database can move to its own instance without code changes.

@@DATABASES_TABLE@@

## Rules

- No service accesses another service's database; exchanges go through APIs or events. No cross-service joins or foreign keys.
- The schema is versioned with **Flyway** (`src/main/resources/db/migration/V<n>__description.sql`). An applied migration is never modified: add a new one.
- Hibernate runs with `ddl-auto: validate`: the schema only changes through migrations.
- Identifiers are application-generated UUIDs (no shared sequence, which simplifies replication and events).
- The shared `postgres` account is for development only. In production: one role per service with rights limited to its database, credentials in a vault or Kubernetes Secret.

## Consistency across services

Consistency is **eventual**: a service reflects another's state by consuming its events. For an operation spanning several services, prefer an event-based saga over a distributed transaction.
