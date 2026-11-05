# 02 — Kafka events

## Topic catalog

@@TOPICS_TABLE@@

## Message format

- Key: aggregate identifier (UUID as a string), which guarantees per-aggregate ordering within a partition.
- Value: UTF-8 JSON.

```json
{ "id": "6f1c…", "name": "example", "occurredAt": "2026-01-01T10:00:00Z" }
```

## Rules

1. **Public contract**: an event is a contract between teams. Add optional fields; never rename or remove without a new topic version.
2. **At-least-once delivery**: consumers are **idempotent** (deduplication on the event `id` or a naturally idempotent operation).
3. **Publish after commit** (`@TransactionalEventListener(AFTER_COMMIT)`): never an event for rolled-back data. Limitation: possible loss if Kafka is unavailable at that moment → plan the Outbox pattern (ADR-0005).
4. **Consumer group** = service name; several instances of a service share the partitions.
5. **Processing errors**: plan a `<topic>.dlt` (dead letter) topic before going to production.

## Inspecting

Kafka UI: http://localhost:8090 (topics, messages, consumer groups).
