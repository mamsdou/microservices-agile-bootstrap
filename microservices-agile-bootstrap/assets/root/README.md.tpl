# @@PROJECT_TITLE@@

> @@DOMAIN@@

**Microservices** application: Spring Boot 3 / Java 21, Spring Cloud (Config, Eureka, Gateway), Angular 15, Kafka, PostgreSQL, ELK, Docker and Kubernetes. Project run with **Scrum** (see `docs/`).

## Context

_To complete: 3-line vision (see `docs/product/vision.md`)._

## Quick start

Prerequisites: Docker (with about 6-8 GB of RAM available for the full stack). To develop without Docker: JDK 21, Maven 3.9+, Node 18.

```bash
docker compose up -d --build
```

| Component | URL |
|---|---|
| Application (Angular) | http://localhost:4200 |
| API Gateway | http://localhost:8080 |
| Eureka (registry) | http://localhost:8761 |
| Config Server | http://localhost:8888 |
| Kibana (logs) | http://localhost:5601 |
| Kafka UI | http://localhost:8090 |
| Keycloak (authentication) | http://localhost:8180 |

The API is protected: a JWT token is required. In the UI (http://localhost:4200), click "Sign in" (development accounts: see [`docs/architecture/06-security.md`](docs/architecture/06-security.md)). Realm roles: @@ROLES_LIST@@.

First end-to-end test from the command line (requires `jq`):

```bash
TOKEN=$(curl -s http://localhost:8180/realms/@@KEYCLOAK_REALM@@/protocol/openid-connect/token \
  -d grant_type=password -d client_id=@@KEYCLOAK_CLIENT_ID@@ \
  -d username=@@FIRST_WRITER@@ -d password=dev-@@FIRST_WRITER@@ | jq -r .access_token)
curl -X POST http://localhost:8080/api/@@FIRST_RESOURCE@@ -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"name":"demo"}'
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/@@FIRST_RESOURCE@@
```

Then watch the consumer react: `docker compose logs -f @@LAST_SERVICE@@`, or in Kibana (`logs-*` data view).

## Structure

```
@@PROJECT@@/
├── pom.xml                  # Maven parent (Java 21, Spring Boot, Spring Cloud)
├── config-server/           # centralized configuration (config-repo/)
├── discovery-server/        # Eureka registry
├── api-gateway/             # single entry point
├── services/                # business microservices (one PostgreSQL database each)
├── frontend/                # Angular 15 (served by nginx)
├── infra/                   # Java Dockerfile, Logstash, PostgreSQL init, Keycloak realm
├── k8s/                     # Kubernetes manifests (kustomize)
├── docker-compose.yml
└── docs/                    # product, agile, architecture, ADR, quality
```

## Documentation

Full index: [`docs/README.md`](docs/README.md). To contribute: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Useful commands

| Command | Effect |
|---|---|
| `mvn -B verify` | build + tests of all modules |
| `docker compose up -d --build` / `down` | start / stop the stack |
| `make images` | build local Docker images |
| `kubectl apply -k k8s` | deploy to Kubernetes (see `docs/architecture/05-deployment.md`) |
