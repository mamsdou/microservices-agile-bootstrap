# 04 — Observability

## Log pipeline

```
Spring service ("elk" profile) → Logstash :5000 (TCP, JSON lines) → Elasticsearch → Kibana
```

- Each module includes `logstash-logback-encoder` and a `logback-spring.xml`: with the Spring `elk` profile, logs go as JSON to Logstash **and** stay on the console (`docker logs`).
- The `app` field (service name) is added to each event; Logstash derives the `logs-<app>-YYYY.MM.DD` index from it.
- Configuration: `infra/elk/logstash/pipeline/logstash.conf`. Use the `LOGSTASH_HOST` variable to target another host.

## Using Kibana

1. Open http://localhost:5601 → *Stack Management* → *Data Views* → create the `logs-*` view with `@timestamp` as the time field.
2. *Discover*: filter by `app`, `level`, `message`.
3. To follow a request across services, add a correlation identifier (to plan: Micrometer Tracing / OpenTelemetry).

## Health and metrics

Spring Actuator exposes `/actuator/health` (liveness/readiness probes for Kubernetes). Prometheus metrics are not enabled yet (see backlog).

## Security warnings

Elasticsearch runs **without authentication** in dev (`xpack.security.enabled=false`). Never expose it outside the local machine; in production, enable Elastic security and TLS.

## Resources

The full ELK stack uses a lot of memory (Elasticsearch 512 MB heap + Logstash + Kibana). On a limited machine, start only the useful services: `docker compose up -d --build postgres kafka keycloak config-server discovery-server api-gateway <services> frontend`, and remove the `elk` profile (`SPRING_PROFILES_ACTIVE` variable).
