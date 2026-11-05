"""Architecture Decision Records (Michael Nygard format) generated with the skeleton.

Each entry describes a decision already embodied in the generated code. The texts are
deliberately short: the team completes them with its real context.
"""

ADRS = [
    {
        "title": "Microservices architecture",
        "context": (
            "The product must evolve through independent business domains, with teams able to "
            "deliver without heavy coordination. A modular monolith would be simpler at first, "
            "but the target organization and the need to scale functions differently justify "
            "separate services."
        ),
        "decision": (
            "Split the system into autonomous business microservices (one service = one bounded "
            "context, its data, its delivery cycle), behind an API Gateway. "
            "Each service is a Spring Boot 3 / Java 21 application."
        ),
        "consequences": (
            "+ Independent deployment and scaling, explicit domain boundaries.\n"
            "- Operational complexity (network, observability, eventual consistency).\n"
            "- Tooling needed from the start (CI/CD, monitoring): covered by this skeleton.\n"
            "Possible review: merge services if the split proves too fine."
        ),
    },
    {
        "title": "Spring Cloud: Config Server, Eureka, Gateway",
        "context": (
            "Configuration must be externalized, instances located dynamically, and a single "
            "entry point offered (routing, CORS, access control)."
        ),
        "decision": (
            "Use Spring Cloud Config Server (`native` backend in dev, files in "
            "`config-server/src/main/resources/config-repo`), Eureka for discovery and "
            "Spring Cloud Gateway for `lb://<service>` routing. `${VAR:default}` placeholders "
            "are resolved on the client side, which keeps the same files for local, "
            "Compose and Kubernetes."
        ),
        "consequences": (
            "+ A single place for configuration; interchangeable services.\n"
            "- Config Server and Eureka become critical startup components.\n"
            "- In production: move the Config Server to an encrypted Git repository and evaluate "
            "native Kubernetes discovery to remove Eureka (new ADR if so)."
        ),
    },
    {
        "title": "One PostgreSQL database per service",
        "context": (
            "Sharing a schema between services recreates strong coupling and prevents "
            "independent deployments."
        ),
        "decision": (
            "Each service owns its logical PostgreSQL database (`<service>_db`), versioned with "
            "Flyway, with Hibernate in `validate` mode. No cross-database access; exchanges go "
            "through APIs or events."
        ),
        "consequences": (
            "+ Autonomy, schema changes with no impact on other services.\n"
            "- No multi-service joins or transactions: eventual consistency, sagas.\n"
            "- In dev a single instance hosts all databases (lower cost)."
        ),
    },
    {
        "title": "Apache Kafka for asynchronous communication",
        "context": (
            "Services must react to each other's business facts without chained synchronous "
            "calls (fragile and coupled in time)."
        ),
        "decision": (
            "Use Kafka (KRaft mode, no ZooKeeper) as the event bus. One `<service>.events` topic "
            "per producing service, JSON messages keyed by aggregate identifier, consumer "
            "group = service name."
        ),
        "consequences": (
            "+ Temporal decoupling, replay possible, scaling through partitions.\n"
            "- Consumers must be idempotent (at-least-once delivery).\n"
            "- Event contract governance needed (see docs/architecture/02)."
        ),
    },
    {
        "title": "Publishing events after commit, Outbox as the target",
        "context": (
            "Publishing to Kafka inside the business transaction is not atomic: an event can be "
            "published for data that is then rolled back, or the reverse."
        ),
        "decision": (
            "Publish through `@TransactionalEventListener(AFTER_COMMIT)`: no event for a "
            "rolled-back transaction. Accept for now the possible loss if Kafka is unavailable "
            "right after commit, and plan the Transactional Outbox pattern (`outbox` table + "
            "relay) in the backlog."
        ),
        "consequences": (
            "+ Simple, no extra dependency, enough to start.\n"
            "- Partial delivery guarantee until the Outbox is in place: "
            "address before any critical flow (payment, billing)."
        ),
    },
    {
        "title": "Observability with the ELK stack through Logstash TCP",
        "context": (
            "Diagnosing an incident in a distributed system requires centralized logs in a "
            "structured format."
        ),
        "decision": (
            "Each service emits JSON logs (`logstash-logback-encoder`) to Logstash (TCP 5000) "
            "with the Spring `elk` profile, in addition to the console. Logstash feeds "
            "Elasticsearch (`logs-<app>-<date>` index), explored in Kibana 8."
        ),
        "consequences": (
            "+ Simple setup, no agent to deploy on nodes.\n"
            "- Logs lost if Logstash is unavailable (reconnection, no disk buffer).\n"
            "- Elastic security disabled in dev; significant memory use.\n"
            "To evaluate later: Filebeat/Elastic Agent, OpenTelemetry distributed tracing."
        ),
    },
    {
        "title": "Angular 15 frontend served by nginx",
        "context": (
            "The web UI must be decoupled from the services and deployable as a static artifact."
        ),
        "decision": (
            "Angular 15 application (NgModule, HttpClient) built in a multi-stage image then "
            "served by nginx, which forwards `/api` to the gateway (same origin, no CORS in "
            "containers). In development `ng serve` uses a proxy to :8080."
        ),
        "consequences": (
            "+ Light image, identical configuration in Compose and Kubernetes.\n"
            "- Angular 15 is no longer actively supported: plan an upgrade "
            "(technical story) before going to production."
        ),
    },
    {
        "title": "Docker containerization and Kubernetes deployment (kustomize)",
        "context": (
            "A reproducible dev environment and an orchestrated production target are needed."
        ),
        "decision": (
            "One generic Java image (`infra/docker/Dockerfile.java`, multi-stage Maven build, "
            "non-root user), a `docker-compose.yml` for the dev machine and Kubernetes manifests "
            "assembled by kustomize (Actuator probes, resources, ConfigMap/Secret)."
        ),
        "consequences": (
            "+ Dev/prod parity, declarative deployment.\n"
            "- Data infrastructure (Postgres, Kafka, Elasticsearch) is single-instance: "
            "replace with operators or managed services in production.\n"
            "- Dev secrets are not suitable for production."
        ),
    },
    {
        "title": "Maven multi-module monorepo",
        "context": (
            "A small team is starting; splitting into one repository per service right away "
            "would multiply the coordination load (versions, reviews, CI)."
        ),
        "decision": (
            "One repository with a parent POM (Java 21, Spring Boot and Spring Cloud BOMs) and "
            "one module per service; `frontend/` and `infra/` in the same repository. Single CI."
        ),
        "consequences": (
            "+ Simple cross-cutting refactorings, aligned versions, fast onboarding.\n"
            "- The pipeline must avoid rebuilding everything on every change (incremental "
            "builds to plan).\n"
            "Can be split into several repositories later if the organization requires it."
        ),
    },
    {
        "title": "Authentication and authorization with Keycloak (OIDC) and JWT",
        "context": (
            "The API must only be accessible to identified users, with different rights "
            "depending on their role. Writing an in-house identity server is costly and risky."
        ),
        "decision": (
            "Use Keycloak as the identity provider (OpenID Connect). The Angular frontend signs "
            "in with the authorization code + PKCE flow (public client, no secret). "
            "The gateway and each service are resource servers: they validate the JWT "
            "(JWKS signature, issuer, expiry). Realm roles (`realm_access.roles`) become Spring "
            "authorities (`ROLE_<name>`); each service declares its write and read roles in "
            "centralized configuration (`app.security.*`). The token is forwarded by the "
            "gateway; services revalidate it (defense in depth)."
        ),
        "consequences": (
            "+ Open standards, SSO, accounts and roles managed outside the code, no password "
            "handled by our services.\n"
            "+ A service called directly remains protected.\n"
            "- Keycloak becomes a critical component to operate (the provided `start-dev` mode "
            "is not suitable for production: dedicated database, HTTPS, high availability).\n"
            "- Roles are not enough for data ownership (a customer sees only their objects): "
            "handle it per domain with the `sub` claim.\n"
            "- The issuer URL must be identical for the browser and the services "
            "(see docs/architecture/06-security.md)."
        ),
    },
]


def render_adr(number: int, adr: dict, date: str) -> str:
    return (
        f"# ADR-{number:04d} — {adr['title']}\n\n"
        f"- **Status**: Accepted\n"
        f"- **Date**: {date}\n\n"
        f"## Context\n\n{adr['context']}\n\n"
        f"## Decision\n\n{adr['decision']}\n\n"
        f"## Consequences\n\n{adr['consequences']}\n"
    )


def render_index(date: str) -> str:
    lines = [
        "# Architecture decisions (ADR)",
        "",
        "Format: [Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions). "
        "An ADR is never rewritten: to change a decision, add a new ADR that supersedes it and "
        "set the old one's status to \"Superseded by ADR-XXXX\".",
        "",
        "| No. | Title | Status |",
        "|---|---|---|",
    ]
    for i, adr in enumerate(ADRS, start=1):
        lines.append(f"| [ADR-{i:04d}](ADR-{i:04d}.md) | {adr['title']} | Accepted |")
    lines.append("")
    return "\n".join(lines)
