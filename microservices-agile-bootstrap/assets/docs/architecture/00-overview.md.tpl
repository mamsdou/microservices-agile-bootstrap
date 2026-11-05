# 00 — Overview

## Context

@@DOMAIN@@

## Container diagram (C4 level 2)

```mermaid
flowchart LR
  user([User]) --> fe[Angular 15 frontend<br/>nginx]
  fe -->|/api + JWT| gw[API Gateway<br/>Spring Cloud Gateway]
  user -.->|OIDC login| kc[(Keycloak)]
  gw -.->|JWKS keys| kc
  gw -.->|discovery| eureka[(Eureka)]
@@MERMAID_SERVICES@@
  cfg[Config Server] -.->|configuration| gw
@@MERMAID_KAFKA@@
  apps[[All Spring services]] -.->|JSON logs| ls[Logstash] --> es[(Elasticsearch)] --> kb[Kibana]
```

## Technical stack

| Layer | Choice | Reference |
|---|---|---|
| Language / framework | Java 21, Spring Boot @@SPRING_BOOT_VERSION@@ | ADR-0001 |
| Cloud-native | Spring Cloud @@SPRING_CLOUD_VERSION@@: Config, Eureka, Gateway | ADR-0002 |
| Data | PostgreSQL 16, one database per service, Flyway | ADR-0003 |
| Messaging | Apache Kafka (KRaft) | ADR-0004, ADR-0005 |
| Observability | Logstash, Elasticsearch, Kibana 8.x | ADR-0006 |
| Frontend | Angular 15 served by nginx | ADR-0007 |
| Deployment | Docker, Docker Compose, Kubernetes (kustomize) | ADR-0008 |
| Build | Maven multi-module, monorepo | ADR-0009 |
| Security | Keycloak (OIDC), JWT, per-service roles | ADR-0010 |

## Guiding principles

1. **Service autonomy**: each service owns its data and deploys alone.
2. **Events for decoupling**: a service publishes business facts, the others react.
3. **Externalized configuration**: the same artifact runs everywhere, only the environment changes.
4. **Observable by default**: structured logs, exposed health, per-service correlation.
5. **Recorded decisions**: every structural choice gets an ADR.

## Out of scope for the initial version

Authorization by data owner (roles only for now), Keycloak hardening for production, application metrics (Prometheus/Grafana), distributed tracing, Outbox pattern, high availability of infrastructure components. These topics are to be planned in the backlog.
