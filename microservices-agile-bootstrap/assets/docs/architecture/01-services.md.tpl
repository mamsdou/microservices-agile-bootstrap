# 01 — Services and ports

## Infrastructure services

| Module | Role | Port | Health |
|---|---|---|---|
| `config-server` | Centralized configuration (`config-repo/`, `native` backend) | 8888 | `/actuator/health` |
| `discovery-server` | Eureka registry | 8761 | `/actuator/health` |
| `api-gateway` | Single entry point, `/api/<resource>/**` routing, CORS | 8080 | `/actuator/health` |

## Business services

@@SERVICES_TABLE@@

Each service exposes `GET`/`POST /api/<resource>`, validates its input, persists through JPA/Flyway and publishes a `<service>.events` event after commit. Services after the first consume the first service's events (a sample flow to replace with real use cases). The entity generated per service (name, creation date) is a **starting point** to rename and enrich for the domain.

## Other components

| Component | Port(s) | Use |
|---|---|---|
| Frontend (nginx) | 4200 → 80 | Angular application, forwards `/api` to the gateway |
| PostgreSQL | 5432 | One database per service |
| Kafka | 9092 (internal), 29092 (host) | Event bus |
| Kafka UI | 8090 | Topic inspection |
| Keycloak | 8180 → 8080 | OIDC authentication, JWT issuing (see `06-security.md`) |
| Elasticsearch | 9200 | Log storage |
| Logstash | 5000 | TCP reception of JSON logs |
| Kibana | 5601 | Log exploration |

In Docker Compose, all these ports are published on `127.0.0.1` only.

## Evolution rules

- Adding a service: see the skill's `references/architecture.md`, then write an ADR if a structural decision is made.
- The ports above are defaults that can be overridden with the `SERVER_PORT` variable.
