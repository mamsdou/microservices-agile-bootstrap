# microservices-agile-bootstrap

**A [Claude Code](https://claude.com/claude-code) skill (and standalone Python generator) that sets up a microservices application in one command — Spring Boot 3 / Java 21, Spring Cloud, Angular 15, Kafka, PostgreSQL, ELK, Keycloak, Docker, Kubernetes — with clear project documentation organized around Scrum.**

> This is the English edition (v0.2.0). The French edition stays available at tag [`v0.1.0`](https://github.com/mamsdou/microservices-agile-bootstrap/tree/v0.1.0). See [CHANGELOG.md](CHANGELOG.md).

## What it is for

Starting a microservices project takes days of plumbing before the first line of business code: Maven parent, Config Server, registry, gateway, databases, event bus, centralized logs, authentication, containers, Kubernetes manifests, CI… then all of it must be documented and the work organized into sprints.

This skill does both:

1. **A coherent skeleton** from a deterministic generator (same parameters, same result).
2. **Documentation ready for an agile team**: architecture decisions (ADRs), Definition of Ready / Done, Scrum working agreement, test strategy, and — written by Claude from your business domain — product vision, roadmap, product backlog as user stories, Sprint 0 / 1, risk register.

## What is generated

```
my-project/
├── pom.xml                  # Maven parent: Java 21, Spring Boot 3.3, Spring Cloud 2023.0
├── config-server/           # centralized configuration (config-repo/: one file per service)
├── discovery-server/        # Eureka registry
├── api-gateway/             # single entry point, requires a valid JWT on /api/**
├── services/<name>-service/ # one microservice per domain: REST, JPA + Flyway, Kafka, role-based security
├── frontend/                # Angular 15 + OIDC login (nginx in a container)
├── infra/                   # Java Dockerfile, Logstash pipeline, PostgreSQL init, Keycloak realm
├── k8s/                     # Kubernetes manifests (kustomize)
├── docker-compose.yml       # PostgreSQL, Kafka (KRaft), Kafka UI, ELK, Keycloak + the services
├── .github/workflows/ci.yml # Maven + Angular build, compose/k8s validation
└── docs/                    # architecture, ADR, agile, quality (+ product and sprints written by Claude)
```

Each generated microservice includes:

- a `GET`/`POST /api/<resource>` REST API with validation, role-based access (401 / 403), unit and security tests;
- **one PostgreSQL database per service**, with a Flyway-versioned schema;
- Kafka event publishing **after commit** (`@TransactionalEventListener`), idempotent consumption to complete;
- JSON logs sent to Logstash → Elasticsearch → Kibana;
- Actuator health probes ready for Kubernetes.

## Requirements

| To… | You need |
|---|---|
| use the skill | [Claude Code](https://claude.com/claude-code) (or any Claude application that supports skills) |
| run the generator alone | Python **3.10+** (no external dependency) |
| build the generated project | JDK 21, Maven 3.9+, Node 18 (Angular 15), Docker |
| run the full stack locally | Docker with about **6 to 8 GB of RAM** available |

## Installation

### As a Claude Code skill

```bash
git clone https://github.com/mamsdou/microservices-agile-bootstrap.git
cp -r microservices-agile-bootstrap/microservices-agile-bootstrap ~/.claude/skills/
```

On Windows (PowerShell):

```powershell
git clone https://github.com/mamsdou/microservices-agile-bootstrap.git
Copy-Item -Recurse microservices-agile-bootstrap\microservices-agile-bootstrap $env:USERPROFILE\.claude\skills\
```

To limit the skill to one project, copy the folder to `<project>/.claude/skills/` instead. Restart Claude Code: the skill is detected automatically.

### Without Claude (generator only)

`microservices-agile-bootstrap/scripts/scaffold.py` works on its own. In that case only the technical part and the generic architecture/agile documents are produced; product documents (vision, backlog…) remain to be written.

## Usage

### With Claude Code

Simply describe your project, for example:

> "Set up a delivery application with microservices using Spring Cloud, Angular, Kafka, PostgreSQL, Keycloak, Docker and Kubernetes, with the Scrum documentation."

Claude derives the services and roles from your domain, runs the generator, writes the product documents, then checks what it can and tells you what was not checked.

### With the script

```bash
python microservices-agile-bootstrap/scripts/scaffold.py \
  --project delivery --title "Delivery" \
  --domain "Delivery application: orders, courier assignment, tracking" \
  --group-id com.example.delivery \
  --roles dispatcher,merchant,courier,customer \
  --services "order:8081:w=merchant+dispatcher:r=customer,delivery:8082:w=dispatcher+courier:r=merchant,courier:8083:w=dispatcher+courier,notification:8084:w=dispatcher:r=customer" \
  --out ./delivery
```

| Option | Purpose |
|---|---|
| `--project` | Project name in kebab-case (also the Keycloak realm name) |
| `--title` / `--domain` | Readable title and one-sentence business domain |
| `--group-id` | Java `groupId` (default `com.example.<project>`) |
| `--roles` | Keycloak realm roles, comma-separated (default `admin,user`) |
| `--services` | Comma-separated `name[:port][:w=role+role][:r=role+role]`. `w` = roles allowed to write (and read), `r` = read-only roles. The **first** service publishes to Kafka, the others consume |
| `--out` | Output folder; refuses to overwrite a non-empty folder unless `--force` is passed |

Then, in the generated project:

```bash
docker compose up -d --build     # full stack
```

| Component | URL |
|---|---|
| Angular application | http://localhost:4200 |
| API Gateway | http://localhost:8080 |
| Keycloak | http://localhost:8180 |
| Eureka / Config Server | http://localhost:8761 / http://localhost:8888 |
| Kibana / Kafka UI | http://localhost:5601 / http://localhost:8090 |

**Development** accounts (one per role) are listed in `docs/architecture/06-security.md` of the generated project.

## Limitations and what has been verified

- ✅ v0.1.0 (French edition) verified: the generator, `docker compose config` and `kubectl kustomize` on the generated files, `mvn verify` and production `ng build`, and the Config Server and secured gateway actually started (401 without a token, health 200, CORS).
- ✅ v0.2.0 verified: the generator, the absence of leftover tokens, YAML parsing and `docker compose config`. It changes text, the Compose port bindings, and a Dockerfile cleanup step.
- ⚠️ **Not verified**: `mvn verify` and `ng build` on v0.2.0, full Docker stack startup, **Keycloak startup** (realm import, `KC_HOSTNAME` issuer URL), the end-to-end Angular login flow, and compilation under **JDK 21**. If you validate them, an issue or PR is welcome.
- The skeleton is a **starting point**: the entity generated per service is deliberately generic, Kafka consumers only log, Keycloak runs in dev mode (H2 database, HTTP) and secrets are dev values. See "To harden before production" in the generated docs.
- Roles protect access to resources but not **data ownership**: handle it per business story.
- Angular 15 is no longer actively supported. Versions are grouped at the top of `scaffold.py` and are updated together.

## Customizing

- **Versions**: constants at the top of [`scripts/scaffold.py`](microservices-agile-bootstrap/scripts/scaffold.py).
- **Generated code, infra and docs**: templates in [`assets/`](microservices-agile-bootstrap/assets) (`.tpl` suffix, `@@NAME@@` tokens in files, `__NAME__` in paths).
- **Architecture decisions**: [`scripts/adrs.py`](microservices-agile-bootstrap/scripts/adrs.py).
- **Claude's behavior**: [`SKILL.md`](microservices-agile-bootstrap/SKILL.md) and [`references/`](microservices-agile-bootstrap/references).

## License

[MIT](LICENSE)
