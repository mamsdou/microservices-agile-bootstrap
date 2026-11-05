#!/usr/bin/env python3
"""Generates a microservices skeleton (Spring Boot 3 / Java 21, Spring Cloud, Angular 15, Kafka,
PostgreSQL, ELK, Docker Compose, Kubernetes) and the associated architecture/agile documentation.

Example:
  python scaffold.py --project shopflow --title "ShopFlow" \
      --domain "E-commerce platform" --group-id com.acme.shopflow \
      --roles admin,merchant,customer \
      --services "catalog:8081:w=admin+merchant:r=customer,order:8082:w=customer+admin:r=merchant,notification:8083:w=admin" \
      --out ./shopflow

Service syntax: name[:port][:w=role+role][:r=role+role]
  w = roles allowed to write (and read), r = read-only roles.
The first service publishes Kafka events, the others consume them.

Templates are in ../assets (.tpl suffix, @@NAME@@ tokens in content, __NAME__ in paths). Files
that depend on the service list (compose, k8s, config-repo, doc tables) are produced here.
"""
from __future__ import annotations

import argparse
import datetime
import html
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from adrs import ADRS, render_adr, render_index  # noqa: E402

ASSETS = HERE.parent / "assets"

# --- Versions: change them together (see references/architecture.md) ------------------------
SPRING_BOOT_VERSION = "3.3.5"
SPRING_CLOUD_VERSION = "2023.0.3"
POSTGRES_IMAGE = "postgres:16-alpine"
KAFKA_IMAGE = "apache/kafka:3.8.0"
KAFKA_UI_IMAGE = "provectuslabs/kafka-ui:v0.7.2"
ELASTIC_VERSION = "8.15.3"
KEYCLOAK_IMAGE = "quay.io/keycloak/keycloak:25.0.6"
IMAGE_TAG = "0.1.0"

RESERVED_PORTS = {
    8080: "api-gateway", 8761: "discovery-server", 8888: "config-server", 8090: "kafka-ui",
    8180: "keycloak",
    4200: "frontend", 5432: "postgres", 9092: "kafka", 29092: "kafka", 9200: "elasticsearch",
    5000: "logstash", 5601: "kibana",
}
JAVA_KEYWORDS = {
    "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class", "const",
    "continue", "default", "do", "double", "else", "enum", "extends", "final", "finally", "float",
    "for", "goto", "if", "implements", "import", "instanceof", "int", "interface", "long",
    "native", "new", "package", "private", "protected", "public", "return", "short", "static",
    "strictfp", "super", "switch", "synchronized", "this", "throw", "throws", "transient", "try",
    "void", "volatile", "while", "record", "var", "yield",
}
KEBAB = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")


def pluralize(word: str) -> str:
    """Simple English plural for REST resource names (delivery -> deliveries)."""
    if re.search(r"[^aeiou]y$", word):
        return word[:-1] + "ies"
    if word.endswith(("s", "x", "z", "ch", "sh")):
        return word + "es"
    return word + "s"


class Service:
    """A business microservice and all the names derived from its name."""

    def __init__(self, spec: str, index: int, group_id: str, roles: list[str]):
        # Syntax: name[:port][:w=role+role][:r=role+role]
        #   w = roles allowed to modify (and read); r = additional read-only roles.
        tokens = [t.strip() for t in spec.strip().split(":")]
        name = tokens[0].lower()
        port = ""
        write: list[str] | None = None
        read: list[str] | None = None
        for token in tokens[1:]:
            if token.isdigit():
                port = token
            elif token.startswith("w="):
                write = [r for r in token[2:].split("+") if r]
            elif token.startswith("r="):
                read = [r for r in token[2:].split("+") if r]
            elif token:
                fail(f"Unknown option '{token}' in '{spec}' (expected: port, w=role+role, r=role+role)")
        if name.endswith("-service"):
            name = name[: -len("-service")]
        if not KEBAB.match(name):
            fail(f"Invalid service name: '{name}' (kebab-case expected, e.g. 'order')")
        parts = name.split("-")
        if any(p in JAVA_KEYWORDS for p in ["".join(parts)] + parts[:1]):
            fail(f"The service name '{name}' is a reserved Java word; choose another one")
        self.index = index
        self.name = name
        self.module = f"{name}-service"
        self.port = int(port) if port else 8081 + index
        self.entity = "".join(p.capitalize() for p in parts)
        self.pkg = "".join(parts)
        self.package = f"{group_id}.{self.pkg}"
        self.resource = "-".join(parts[:-1] + [pluralize(parts[-1])])
        self.table = self.resource.replace("-", "_")
        self.db = f"{name.replace('-', '_')}_db"
        self.topic = f"{name}.events"
        self.label = " ".join(p.capitalize() for p in parts) + "s"
        # Default rights: the first role writes, the others read. If w= is given without r=,
        # nobody else reads.
        self.write_roles = write if write is not None else roles[:1]
        if read is not None:
            self.read_roles = read
        else:
            self.read_roles = [] if write is not None else roles[1:]
        unknown = [r for r in self.write_roles + self.read_roles if r not in roles]
        if unknown or not self.write_roles:
            fail(f"Unknown or missing roles for '{name}': {unknown or 'no write role'} "
                 f"(declared roles: {', '.join(roles)})")


def fail(message: str) -> None:
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)


# --- template rendering -----------------------------------------------------------------------
def render(text: str, tokens: dict[str, str]) -> str:
    for key in sorted(tokens, key=len, reverse=True):
        text = text.replace(f"@@{key}@@", str(tokens[key]))
    return text


def render_path(path: str, name_tokens: dict[str, str]) -> str:
    for key in sorted(name_tokens, key=len, reverse=True):
        path = path.replace(f"__{key}__", name_tokens[key])
    return path


class Writer:
    def __init__(self, root: Path):
        self.root = root
        self.files: list[Path] = []

    def write(self, rel: str, content: str) -> None:
        target = self.root / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8", newline="\n")
        self.files.append(target)

    def copy_tree(self, src: Path, dest_rel: str, tokens: dict[str, str],
                  name_tokens: dict[str, str] | None = None) -> None:
        if not src.is_dir():
            fail(f"Templates not found: {src}")
        for path in sorted(src.rglob("*")):
            if not path.is_file():
                continue
            rel = render_path(path.relative_to(src).as_posix(), name_tokens or {})
            if rel.endswith(".tpl"):
                rel = rel[: -len(".tpl")]
            dest = f"{dest_rel}/{rel}" if dest_rel else rel
            self.write(dest, render(path.read_text(encoding="utf-8"), tokens))


# --- files generated from the service list ---------------------------------------------------
def indent(text: str, spaces: int) -> str:
    pad = " " * spaces
    return "\n".join(pad + line if line.strip() else line for line in text.splitlines())


def config_repo(services: list[Service], realm: str) -> dict[str, str]:
    files = {
        "application.yml": (
            "# Configuration shared by ALL services (served by the Config Server).\n"
            "eureka:\n"
            "  client:\n"
            "    service-url:\n"
            "      defaultZone: ${EUREKA_URL:http://localhost:8761/eureka}\n"
            "  instance:\n"
            "    prefer-ip-address: true\n"
            "\n"
            "management:\n"
            "  endpoint:\n"
            "    health:\n"
            "      probes:\n"
            "        enabled: true\n"
            "  endpoints:\n"
            "    web:\n"
            "      exposure:\n"
            "        include: health,info\n"
            "\n"
            "spring:\n"
            "  security:\n"
            "    oauth2:\n"
            "      resourceserver:\n"
            "        jwt:\n"
            "          # expected iss = public Keycloak URL (the one seen by the browser);\n"
            "          # signing keys are read through the internal address (jwk-set-uri).\n"
            f"          issuer-uri: ${{KEYCLOAK_ISSUER:http://localhost:8180/realms/{realm}}}\n"
            f"          jwk-set-uri: ${{KEYCLOAK_JWKS:http://localhost:8180/realms/{realm}/protocol/openid-connect/certs}}\n"
        )
    }
    routes = "".join(
        f"        - id: {s.module}\n"
        f"          uri: lb://{s.module}\n"
        f"          predicates:\n"
        f"            - Path=/api/{s.resource}/**\n"
        for s in services
    )
    files["api-gateway.yml"] = (
        "spring:\n"
        "  cloud:\n"
        "    gateway:\n"
        "      routes:\n"
        f"{routes}"
        "      globalcors:\n"
        "        cors-configurations:\n"
        "          '[/**]':\n"
        "            allowedOrigins:\n"
        "              - \"http://localhost:4200\"\n"
        "            allowedMethods: [GET, POST, PUT, PATCH, DELETE, OPTIONS]\n"
        "            allowedHeaders: \"*\"\n"
    )
    first = services[0]
    for s in services:
        source = "" if s is first else f"    source-topic: {first.topic}\n"
        files[f"{s.module}.yml"] = (
            "spring:\n"
            "  datasource:\n"
            f"    url: jdbc:postgresql://${{DB_HOST:localhost}}:${{DB_PORT:5432}}/{s.db}\n"
            "    username: ${DB_USER:postgres}\n"
            "    password: ${DB_PASSWORD:postgres}\n"
            "  jpa:\n"
            "    open-in-view: false\n"
            "    hibernate:\n"
            "      ddl-auto: validate\n"
            "  kafka:\n"
            "    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:29092}\n"
            "    producer:\n"
            "      key-serializer: org.apache.kafka.common.serialization.StringSerializer\n"
            "      value-serializer: org.apache.kafka.common.serialization.StringSerializer\n"
            "    consumer:\n"
            f"      group-id: {s.module}\n"
            "      auto-offset-reset: earliest\n"
            "      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer\n"
            "      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer\n"
            "app:\n"
            "  kafka:\n"
            f"    topic: {s.topic}\n"
            f"{source}"
            "  security:\n"
            f"    read-roles: \"{','.join(s.read_roles)}\"\n"
            f"    write-roles: \"{','.join(s.write_roles)}\"\n"
        )
    return files


def init_db_sql(services: list[Service]) -> str:
    lines = ["-- One database per service (run at the first PostgreSQL startup).\n"]
    lines += [f"CREATE DATABASE {s.db};\n" for s in services]
    return "".join(lines)


def compose(project: str, services: list[Service], realm: str) -> str:
    def java(name: str, path: str, port: int, extra_env: str = "", depends: str = "") -> str:
        return (
            f"  {name}:\n"
            f"    build:\n"
            f"      context: .\n"
            f"      dockerfile: infra/docker/Dockerfile.java\n"
            f"      args:\n"
            f"        MODULE_PATH: {path}\n"
            f"    image: {project}/{name}:{IMAGE_TAG}\n"
            f"    restart: unless-stopped\n"
            f"    environment:\n"
            f"      <<: *java-env\n"
            f"{extra_env}"
            f"    ports:\n"
            f"      - \"127.0.0.1:{port}:{port}\"\n"
            f"{depends}"
            f"    healthcheck:\n"
            f"      test: [\"CMD\", \"curl\", \"-fs\", \"http://localhost:{port}/actuator/health\"]\n"
            f"      interval: 10s\n"
            f"      timeout: 5s\n"
            f"      retries: 20\n"
            f"      start_period: 60s\n"
        )

    healthy = lambda *names: (  # noqa: E731
        "    depends_on:\n"
        + "".join(f"      {n}:\n        condition: service_healthy\n" for n in names)
    )
    domain_env = (
        "      DB_HOST: postgres\n"
        "      DB_USER: ${POSTGRES_USER:-postgres}\n"
        "      DB_PASSWORD: ${POSTGRES_PASSWORD:-postgres}\n"
        "      KAFKA_BOOTSTRAP_SERVERS: kafka:9092\n"
    )
    domain_deps = (
        "    depends_on:\n"
        "      config-server:\n        condition: service_healthy\n"
        "      discovery-server:\n        condition: service_healthy\n"
        "      postgres:\n        condition: service_healthy\n"
        "      kafka:\n        condition: service_started\n"
    )

    out = [
        f"name: {project}\n\n"
        "# Full DEVELOPMENT stack (~6-8 GB of RAM). Insecure default values.\n"
        "x-java-env: &java-env\n"
        "  SPRING_PROFILES_ACTIVE: elk\n"
        "  LOGSTASH_HOST: logstash\n"
        "  CONFIG_SERVER_URL: http://config-server:8888\n"
        "  EUREKA_URL: http://discovery-server:8761/eureka\n"
        f"  KEYCLOAK_JWKS: http://keycloak:8080/realms/{realm}/protocol/openid-connect/certs\n\n"
        "services:\n",
        "  # ---------- Infrastructure Spring Cloud ----------\n",
        java("config-server", "config-server", 8888,
             extra_env="      SPRING_PROFILES_ACTIVE: native,elk\n"),
        java("discovery-server", "discovery-server", 8761),
        java("api-gateway", "api-gateway", 8080,
             depends=healthy("config-server", "discovery-server")),
        "  # ---------- Business microservices ----------\n",
    ]
    for s in services:
        out.append(java(s.module, f"services/{s.module}", s.port,
                        extra_env=domain_env, depends=domain_deps))
    out.append(
        "  # ---------- Frontend ----------\n"
        "  frontend:\n"
        "    build:\n"
        "      context: frontend\n"
        f"    image: {project}/frontend:{IMAGE_TAG}\n"
        "    restart: unless-stopped\n"
        "    ports:\n"
        "      - \"127.0.0.1:4200:80\"\n"
        "    depends_on:\n"
        "      api-gateway:\n"
        "        condition: service_started\n\n"
        "  # ---------- Data and messaging ----------\n"
        "  postgres:\n"
        f"    image: {POSTGRES_IMAGE}\n"
        "    restart: unless-stopped\n"
        "    environment:\n"
        "      POSTGRES_USER: ${POSTGRES_USER:-postgres}\n"
        "      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}\n"
        "    ports:\n"
        "      - \"127.0.0.1:5432:5432\"\n"
        "    volumes:\n"
        "      - pgdata:/var/lib/postgresql/data\n"
        "      - ./infra/docker/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql:ro\n"
        "    healthcheck:\n"
        "      test: [\"CMD-SHELL\", \"pg_isready -U $${POSTGRES_USER:-postgres}\"]\n"
        "      interval: 5s\n"
        "      timeout: 5s\n"
        "      retries: 20\n\n"
        "  kafka:\n"
        f"    image: {KAFKA_IMAGE}\n"
        "    restart: unless-stopped\n"
        "    ports:\n"
        "      - \"127.0.0.1:29092:29092\"\n"
        "    environment:\n"
        "      KAFKA_NODE_ID: 1\n"
        "      KAFKA_PROCESS_ROLES: broker,controller\n"
        "      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093,EXTERNAL://:29092\n"
        "      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,EXTERNAL://localhost:29092\n"
        "      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT\n"
        "      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093\n"
        "      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER\n"
        "      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT\n"
        "      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1\n"
        "      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1\n"
        "      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1\n"
        "      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0\n\n"
        "  kafka-ui:\n"
        f"    image: {KAFKA_UI_IMAGE}\n"
        "    restart: unless-stopped\n"
        "    environment:\n"
        "      KAFKA_CLUSTERS_0_NAME: local\n"
        "      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092\n"
        "    ports:\n"
        "      - \"127.0.0.1:8090:8080\"\n"
        "    depends_on:\n"
        "      - kafka\n\n"
        "  # ---------- ELK stack (security disabled: dev only) ----------\n"
        "  elasticsearch:\n"
        f"    image: docker.elastic.co/elasticsearch/elasticsearch:{ELASTIC_VERSION}\n"
        "    restart: unless-stopped\n"
        "    environment:\n"
        "      discovery.type: single-node\n"
        "      xpack.security.enabled: \"false\"\n"
        "      ES_JAVA_OPTS: -Xms512m -Xmx512m\n"
        "    ports:\n"
        "      - \"127.0.0.1:9200:9200\"\n"
        "    volumes:\n"
        "      - esdata:/usr/share/elasticsearch/data\n"
        "    healthcheck:\n"
        "      test: [\"CMD-SHELL\", \"curl -fs http://localhost:9200/_cluster/health || exit 1\"]\n"
        "      interval: 10s\n"
        "      timeout: 5s\n"
        "      retries: 30\n"
        "      start_period: 30s\n\n"
        "  logstash:\n"
        f"    image: docker.elastic.co/logstash/logstash:{ELASTIC_VERSION}\n"
        "    restart: unless-stopped\n"
        "    environment:\n"
        "      LS_JAVA_OPTS: -Xms256m -Xmx256m\n"
        "      XPACK_MONITORING_ENABLED: \"false\"\n"
        "    volumes:\n"
        "      - ./infra/elk/logstash/pipeline/logstash.conf:/usr/share/logstash/pipeline/logstash.conf:ro\n"
        "    ports:\n"
        "      - \"127.0.0.1:5000:5000\"\n"
        "    depends_on:\n"
        "      elasticsearch:\n"
        "        condition: service_healthy\n\n"
        "  kibana:\n"
        f"    image: docker.elastic.co/kibana/kibana:{ELASTIC_VERSION}\n"
        "    restart: unless-stopped\n"
        "    environment:\n"
        "      ELASTICSEARCH_HOSTS: http://elasticsearch:9200\n"
        "    ports:\n"
        "      - \"127.0.0.1:5601:5601\"\n"
        "    depends_on:\n"
        "      elasticsearch:\n"
        "        condition: service_healthy\n\n"
        "  # ---------- Authentication: Keycloak in dev mode (H2, imported realm) ----------\n"
        "  keycloak:\n"
        f"    image: {KEYCLOAK_IMAGE}\n"
        "    command: [\"start-dev\", \"--import-realm\"]\n"
        "    restart: unless-stopped\n"
        "    environment:\n"
        "      KEYCLOAK_ADMIN: ${KEYCLOAK_ADMIN:-admin}\n"
        "      KEYCLOAK_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD:-admin}\n"
        "      KC_HOSTNAME: http://localhost:8180\n"
        "      KC_HOSTNAME_BACKCHANNEL_DYNAMIC: \"true\"\n"
        "      KC_HTTP_ENABLED: \"true\"\n"
        "    ports:\n"
        "      - \"127.0.0.1:8180:8080\"\n"
        "    volumes:\n"
        "      - ./infra/keycloak/realm.json:/opt/keycloak/data/import/realm.json:ro\n"
        "\n"
        "volumes:\n"
        "  pgdata:\n"
        "  esdata:\n"
    )
    return "".join(out)


def makefile(project: str, services: list[Service]) -> str:
    images = [("config-server", "config-server"), ("discovery-server", "discovery-server"),
              ("api-gateway", "api-gateway")]
    images += [(s.module, f"services/{s.module}") for s in services]
    lines = [
        ".PHONY: build up down images k8s-apply k8s-delete\n\n"
        "build:\n\tmvn -B verify\n\n"
        "up:\n\tdocker compose up -d --build\n\n"
        "down:\n\tdocker compose down\n\n"
        "images:\n"
    ]
    for name, path in images:
        lines.append(
            f"\tdocker build -f infra/docker/Dockerfile.java --build-arg MODULE_PATH={path} "
            f"-t {project}/{name}:{IMAGE_TAG} .\n"
        )
    lines.append(f"\tdocker build -t {project}/frontend:{IMAGE_TAG} frontend\n\n")
    lines.append("k8s-apply:\n\tkubectl apply -k k8s\n\nk8s-delete:\n\tkubectl delete -k k8s\n")
    return "".join(lines)


# --- Keycloak ---------------------------------------------------------------------------------
def dev_password(role: str) -> str:
    return f"dev-{role}"


def keycloak_realm(realm: str, client_id: str, roles: list[str]) -> str:
    """Realm imported at Keycloak startup: roles, public Angular client (PKCE), one development
    account per role. Dev passwords must never be used in production."""
    doc = {
        "realm": realm,
        "enabled": True,
        "sslRequired": "external",
        "registrationAllowed": False,
        "roles": {"realm": [{"name": r} for r in roles]},
        "clients": [{
            "clientId": client_id,
            "protocol": "openid-connect",
            "enabled": True,
            "publicClient": True,
            "standardFlowEnabled": True,
            # Handy in dev to get a token with curl; disable in production.
            "directAccessGrantsEnabled": True,
            "redirectUris": ["http://localhost:4200/*"],
            "webOrigins": ["http://localhost:4200"],
            "attributes": {"pkce.code.challenge.method": "S256"},
        }],
        "users": [{
            "username": r,
            "enabled": True,
            "emailVerified": True,
            "email": f"{r}@example.test",
            "firstName": "Dev",
            "lastName": r.capitalize(),
            "credentials": [{"type": "password", "value": dev_password(r), "temporary": False}],
            "realmRoles": [r],
        } for r in roles],
    }
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"


def security_tokens(services: list[Service], roles: list[str], realm: str, client_id: str) -> dict[str, str]:
    matrix = ["| Service | Write (POST/PUT/DELETE) | Additional read-only (GET) |", "|---|---|---|"]
    for s in services:
        matrix.append(f"| `{s.module}` | {', '.join(s.write_roles)} | {', '.join(s.read_roles) or '—'} |")
    users = ["| User | Password (dev) | Role |", "|---|---|---|"]
    users += [f"| `{r}` | `{dev_password(r)}` | {r} |" for r in roles]
    return {
        "KEYCLOAK_REALM": realm, "KEYCLOAK_CLIENT_ID": client_id,
        "ROLES_LIST": ", ".join(roles), "FIRST_WRITER": services[0].write_roles[0],
        "SECURITY_MATRIX": "\n".join(matrix), "DEV_USERS_TABLE": "\n".join(users),
    }


# --- Kubernetes -------------------------------------------------------------------------------
def k8s_keycloak(realm_doc: str) -> str:
    return (
        "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: keycloak-realm\n"
        "data:\n  realm.json: |\n" + indent(realm_doc, 4) + "\n"
        "---\n"
        "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: keycloak\n"
        "spec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: keycloak\n"
        "  template:\n    metadata:\n      labels:\n        app: keycloak\n"
        "    spec:\n      enableServiceLinks: false\n      containers:\n"
        "        - name: keycloak\n"
        f"          image: {KEYCLOAK_IMAGE}\n"
        "          args: [\"start-dev\", \"--import-realm\"]\n"
        "          ports:\n            - containerPort: 8080\n"
        "          env:\n"
        "            - name: KEYCLOAK_ADMIN\n              valueFrom:\n                secretKeyRef:\n                  name: app-secret\n                  key: KEYCLOAK_ADMIN\n"
        "            - name: KEYCLOAK_ADMIN_PASSWORD\n              valueFrom:\n                secretKeyRef:\n                  name: app-secret\n                  key: KEYCLOAK_ADMIN_PASSWORD\n"
        "            # Public URL seen by the browser (kubectl port-forward svc/keycloak 8180:8080).\n"
        "            - {name: KC_HOSTNAME, value: \"http://localhost:8180\"}\n"
        "            - {name: KC_HOSTNAME_BACKCHANNEL_DYNAMIC, value: \"true\"}\n"
        "            - {name: KC_HTTP_ENABLED, value: \"true\"}\n"
        "          readinessProbe:\n            tcpSocket:\n              port: 8080\n            initialDelaySeconds: 60\n            periodSeconds: 10\n            failureThreshold: 12\n"
        "          resources:\n            requests:\n              memory: 768Mi\n            limits:\n              memory: 1Gi\n"
        "          volumeMounts:\n            - name: realm\n              mountPath: /opt/keycloak/data/import\n"
        "      volumes:\n        - name: realm\n          configMap:\n            name: keycloak-realm\n"
        "---\n"
        "apiVersion: v1\nkind: Service\nmetadata:\n  name: keycloak\n"
        "spec:\n  selector:\n    app: keycloak\n  ports:\n    - port: 8080\n      targetPort: 8080\n"
    )


def k8s_app(name: str, project: str, port: int, *, wait_for_config: bool = False,
            extra_env: dict[str, str] | None = None, probe_path: str | None = None,
            image: str | None = None, memory: str = "768Mi",
            mount: tuple[str, str, str] | None = None) -> str:
    image = image or f"{project}/{name}:{IMAGE_TAG}"
    mount_block = volumes_block = ""
    if mount:  # (ConfigMap name, key, container path) mounted through subPath
        cm_name, cm_key, cm_path = mount
        mount_block = (
            "          volumeMounts:\n"
            f"            - name: cfg\n              mountPath: {cm_path}\n              subPath: {cm_key}\n"
        )
        volumes_block = f"      volumes:\n        - name: cfg\n          configMap:\n            name: {cm_name}\n"
    ready = f"{probe_path}" if probe_path else "/actuator/health/readiness"
    live = f"{probe_path}" if probe_path else "/actuator/health/liveness"
    env_block = ""
    if extra_env:
        env_block = "          env:\n" + "".join(
            f"            - name: {k}\n              value: \"{v}\"\n" for k, v in extra_env.items()
        )
    init = ""
    if wait_for_config:
        init = (
            "      initContainers:\n"
            "        - name: wait-for-config-server\n"
            "          image: busybox:1.36\n"
            "          command: [\"sh\", \"-c\", \"until wget -q -O /dev/null http://config-server:8888/actuator/health; do echo waiting for config-server; sleep 3; done\"]\n"
        )
    env_from = ""
    if probe_path is None:  # Spring applications: shared configuration
        env_from = (
            "          envFrom:\n"
            "            - configMapRef:\n                name: app-config\n"
            "            - secretRef:\n                name: app-secret\n"
        )
    return (
        "apiVersion: apps/v1\n"
        "kind: Deployment\n"
        f"metadata:\n  name: {name}\n  labels:\n    app: {name}\n"
        "spec:\n"
        "  replicas: 1\n"
        f"  selector:\n    matchLabels:\n      app: {name}\n"
        "  template:\n"
        f"    metadata:\n      labels:\n        app: {name}\n"
        "    spec:\n"
        "      enableServiceLinks: false\n"
        f"{init}"
        "      containers:\n"
        f"        - name: {name}\n"
        f"          image: {image}\n"
        "          imagePullPolicy: IfNotPresent\n"
        f"          ports:\n            - containerPort: {port}\n"
        f"{env_from}"
        f"{env_block}"
        "          readinessProbe:\n"
        f"            httpGet:\n              path: {ready}\n              port: {port}\n"
        "            initialDelaySeconds: 30\n            periodSeconds: 10\n            failureThreshold: 12\n"
        "          livenessProbe:\n"
        f"            httpGet:\n              path: {live}\n              port: {port}\n"
        "            initialDelaySeconds: 90\n            periodSeconds: 15\n            failureThreshold: 6\n"
        "          resources:\n"
        f"            requests:\n              cpu: 100m\n              memory: {memory}\n"
        f"            limits:\n              memory: {memory}\n"
        f"{mount_block}"
        f"{volumes_block}"
        "---\n"
        "apiVersion: v1\n"
        "kind: Service\n"
        f"metadata:\n  name: {name}\n  labels:\n    app: {name}\n"
        f"spec:\n  selector:\n    app: {name}\n  ports:\n    - port: {port}\n      targetPort: {port}\n"
    )


def k8s_manifests(project: str, services: list[Service], init_sql: str,
                  logstash_conf: str, realm: str, realm_doc: str) -> dict[str, str]:
    files: dict[str, str] = {}
    files["namespace.yaml"] = f"apiVersion: v1\nkind: Namespace\nmetadata:\n  name: {project}\n"
    files["configmap.yaml"] = (
        "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: app-config\n"
        "data:\n"
        "  SPRING_PROFILES_ACTIVE: elk\n"
        "  LOGSTASH_HOST: logstash\n"
        "  CONFIG_SERVER_URL: http://config-server:8888\n"
        "  EUREKA_URL: http://discovery-server:8761/eureka\n"
        "  DB_HOST: postgres\n"
        "  KAFKA_BOOTSTRAP_SERVERS: kafka:9092\n"
        f"  KEYCLOAK_JWKS: http://keycloak:8080/realms/{realm}/protocol/openid-connect/certs\n"
    )
    files["secret.yaml"] = (
        "# WARNING: plain DEVELOPMENT values. In production, use Sealed Secrets,\n"
        "# External Secrets or Vault and never commit real credentials.\n"
        "apiVersion: v1\nkind: Secret\nmetadata:\n  name: app-secret\ntype: Opaque\n"
        "stringData:\n  DB_USER: postgres\n  DB_PASSWORD: postgres\n"
        "  KEYCLOAK_ADMIN: admin\n  KEYCLOAK_ADMIN_PASSWORD: admin\n"
    )
    files["keycloak.yaml"] = k8s_keycloak(realm_doc)
    files["postgres.yaml"] = (
        "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: postgres-init\n"
        "data:\n  init-db.sql: |\n" + indent(init_sql, 4) + "\n"
        "---\n"
        "apiVersion: apps/v1\nkind: StatefulSet\nmetadata:\n  name: postgres\n"
        "spec:\n  serviceName: postgres\n  replicas: 1\n"
        "  selector:\n    matchLabels:\n      app: postgres\n"
        "  template:\n    metadata:\n      labels:\n        app: postgres\n"
        "    spec:\n      enableServiceLinks: false\n      containers:\n"
        "        - name: postgres\n"
        f"          image: {POSTGRES_IMAGE}\n"
        "          ports:\n            - containerPort: 5432\n"
        "          env:\n"
        "            - name: POSTGRES_USER\n              valueFrom:\n                secretKeyRef:\n                  name: app-secret\n                  key: DB_USER\n"
        "            - name: POSTGRES_PASSWORD\n              valueFrom:\n                secretKeyRef:\n                  name: app-secret\n                  key: DB_PASSWORD\n"
        "            - name: PGDATA\n              value: /var/lib/postgresql/data/pgdata\n"
        "          readinessProbe:\n            exec:\n              command: [\"sh\", \"-c\", \"pg_isready -U \\\"$POSTGRES_USER\\\"\"]\n"
        "            periodSeconds: 5\n"
        "          volumeMounts:\n"
        "            - name: data\n              mountPath: /var/lib/postgresql/data\n"
        "            - name: init\n              mountPath: /docker-entrypoint-initdb.d\n"
        "      volumes:\n        - name: init\n          configMap:\n            name: postgres-init\n"
        "  volumeClaimTemplates:\n    - metadata:\n        name: data\n      spec:\n"
        "        accessModes: [\"ReadWriteOnce\"]\n        resources:\n          requests:\n            storage: 2Gi\n"
        "---\n"
        "apiVersion: v1\nkind: Service\nmetadata:\n  name: postgres\n"
        "spec:\n  selector:\n    app: postgres\n  ports:\n    - port: 5432\n      targetPort: 5432\n"
    )
    files["kafka.yaml"] = (
        "apiVersion: apps/v1\nkind: StatefulSet\nmetadata:\n  name: kafka\n"
        "spec:\n  serviceName: kafka\n  replicas: 1\n"
        "  selector:\n    matchLabels:\n      app: kafka\n"
        "  template:\n    metadata:\n      labels:\n        app: kafka\n"
        "    spec:\n      enableServiceLinks: false\n      containers:\n"
        "        - name: kafka\n"
        f"          image: {KAFKA_IMAGE}\n"
        "          ports:\n            - containerPort: 9092\n"
        "          env:\n"
        "            - {name: KAFKA_NODE_ID, value: \"1\"}\n"
        "            - {name: KAFKA_PROCESS_ROLES, value: \"broker,controller\"}\n"
        "            - {name: KAFKA_LISTENERS, value: \"PLAINTEXT://:9092,CONTROLLER://:9093\"}\n"
        "            - {name: KAFKA_ADVERTISED_LISTENERS, value: \"PLAINTEXT://kafka:9092\"}\n"
        "            - {name: KAFKA_LISTENER_SECURITY_PROTOCOL_MAP, value: \"CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT\"}\n"
        "            - {name: KAFKA_CONTROLLER_QUORUM_VOTERS, value: \"1@kafka:9093\"}\n"
        "            - {name: KAFKA_CONTROLLER_LISTENER_NAMES, value: \"CONTROLLER\"}\n"
        "            - {name: KAFKA_INTER_BROKER_LISTENER_NAME, value: \"PLAINTEXT\"}\n"
        "            - {name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR, value: \"1\"}\n"
        "            - {name: KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR, value: \"1\"}\n"
        "            - {name: KAFKA_TRANSACTION_STATE_LOG_MIN_ISR, value: \"1\"}\n"
        "            - {name: KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS, value: \"0\"}\n"
        "          readinessProbe:\n            tcpSocket:\n              port: 9092\n            initialDelaySeconds: 20\n            periodSeconds: 10\n"
        "          volumeMounts:\n            - name: data\n              mountPath: /var/lib/kafka/data\n"
        "  volumeClaimTemplates:\n    - metadata:\n        name: data\n      spec:\n"
        "        accessModes: [\"ReadWriteOnce\"]\n        resources:\n          requests:\n            storage: 2Gi\n"
        "---\n"
        "apiVersion: v1\nkind: Service\nmetadata:\n  name: kafka\n"
        "spec:\n  selector:\n    app: kafka\n  ports:\n    - port: 9092\n      targetPort: 9092\n"
    )
    files["elk.yaml"] = (
        "# Minimal ELK stack (single instance, security disabled: DEV only).\n"
        "apiVersion: apps/v1\nkind: StatefulSet\nmetadata:\n  name: elasticsearch\n"
        "spec:\n  serviceName: elasticsearch\n  replicas: 1\n"
        "  selector:\n    matchLabels:\n      app: elasticsearch\n"
        "  template:\n    metadata:\n      labels:\n        app: elasticsearch\n"
        "    spec:\n      enableServiceLinks: false\n      containers:\n"
        "        - name: elasticsearch\n"
        f"          image: docker.elastic.co/elasticsearch/elasticsearch:{ELASTIC_VERSION}\n"
        "          ports:\n            - containerPort: 9200\n"
        "          env:\n"
        "            - {name: discovery.type, value: single-node}\n"
        "            - {name: xpack.security.enabled, value: \"false\"}\n"
        "            - {name: ES_JAVA_OPTS, value: \"-Xms512m -Xmx512m\"}\n"
        "          readinessProbe:\n            httpGet:\n              path: /_cluster/health\n              port: 9200\n            initialDelaySeconds: 30\n            periodSeconds: 10\n"
        "          resources:\n            requests:\n              memory: 1Gi\n            limits:\n              memory: 1Gi\n"
        "          volumeMounts:\n            - name: data\n              mountPath: /usr/share/elasticsearch/data\n"
        "  volumeClaimTemplates:\n    - metadata:\n        name: data\n      spec:\n"
        "        accessModes: [\"ReadWriteOnce\"]\n        resources:\n          requests:\n            storage: 5Gi\n"
        "---\n"
        "apiVersion: v1\nkind: Service\nmetadata:\n  name: elasticsearch\n"
        "spec:\n  selector:\n    app: elasticsearch\n  ports:\n    - port: 9200\n      targetPort: 9200\n"
        "---\n"
        "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: logstash-pipeline\n"
        "data:\n  logstash.conf: |\n" + indent(logstash_conf, 4) + "\n"
        "---\n"
        "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: logstash\n"
        "spec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: logstash\n"
        "  template:\n    metadata:\n      labels:\n        app: logstash\n"
        "    spec:\n      enableServiceLinks: false\n      containers:\n"
        "        - name: logstash\n"
        f"          image: docker.elastic.co/logstash/logstash:{ELASTIC_VERSION}\n"
        "          ports:\n            - containerPort: 5000\n"
        "          env:\n"
        "            - {name: LS_JAVA_OPTS, value: \"-Xms256m -Xmx256m\"}\n"
        "            - {name: XPACK_MONITORING_ENABLED, value: \"false\"}\n"
        "          resources:\n            requests:\n              memory: 768Mi\n            limits:\n              memory: 768Mi\n"
        "          volumeMounts:\n            - name: pipeline\n              mountPath: /usr/share/logstash/pipeline\n"
        "      volumes:\n        - name: pipeline\n          configMap:\n            name: logstash-pipeline\n"
        "---\n"
        "apiVersion: v1\nkind: Service\nmetadata:\n  name: logstash\n"
        "spec:\n  selector:\n    app: logstash\n  ports:\n    - port: 5000\n      targetPort: 5000\n"
        "---\n"
        "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: kibana\n"
        "spec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: kibana\n"
        "  template:\n    metadata:\n      labels:\n        app: kibana\n"
        "    spec:\n      enableServiceLinks: false\n      containers:\n"
        "        - name: kibana\n"
        f"          image: docker.elastic.co/kibana/kibana:{ELASTIC_VERSION}\n"
        "          ports:\n            - containerPort: 5601\n"
        "          env:\n            - {name: ELASTICSEARCH_HOSTS, value: \"http://elasticsearch:9200\"}\n"
        "          readinessProbe:\n            httpGet:\n              path: /api/status\n              port: 5601\n            initialDelaySeconds: 60\n            periodSeconds: 15\n"
        "          resources:\n            requests:\n              memory: 768Mi\n            limits:\n              memory: 1Gi\n"
        "---\n"
        "apiVersion: v1\nkind: Service\nmetadata:\n  name: kibana\n"
        "spec:\n  selector:\n    app: kibana\n  ports:\n    - port: 5601\n      targetPort: 5601\n"
    )
    files["config-server.yaml"] = k8s_app(
        "config-server", project, 8888, extra_env={"SPRING_PROFILES_ACTIVE": "native,elk"})
    files["discovery-server.yaml"] = k8s_app("discovery-server", project, 8761)
    files["api-gateway.yaml"] = k8s_app("api-gateway", project, 8080, wait_for_config=True)
    for s in services:
        files[f"{s.module}.yaml"] = k8s_app(s.module, project, s.port, wait_for_config=True)
    files["frontend.yaml"] = (
        "# Front runtime configuration (see frontend/src/config.js). Keycloak is reached by the browser:\n"
        "# here through kubectl port-forward svc/keycloak 8180:8080; adapt with an Ingress.\n"
        "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: frontend-config\n"
        "data:\n  config.js: |\n"
        "    window.APP_CONFIG = {\n"
        "      keycloakUrl: 'http://localhost:8180',\n"
        f"      realm: '{realm}',\n"
        f"      clientId: '{realm}-frontend'\n"
        "    };\n"
        "---\n"
        + k8s_app("frontend", project, 80, probe_path="/", memory="128Mi",
                  mount=("frontend-config", "config.js", "/usr/share/nginx/html/config.js"))
    )
    files["ingress.yaml"] = (
        "apiVersion: networking.k8s.io/v1\nkind: Ingress\nmetadata:\n  name: " + project + "\n"
        "spec:\n  rules:\n"
        f"    - host: {project}.local\n"
        "      http:\n        paths:\n          - path: /\n            pathType: Prefix\n"
        "            backend:\n              service:\n                name: frontend\n"
        "                port:\n                  number: 80\n"
    )
    resources = ["namespace.yaml", "configmap.yaml", "secret.yaml", "postgres.yaml", "kafka.yaml",
                 "elk.yaml", "keycloak.yaml", "config-server.yaml", "discovery-server.yaml", "api-gateway.yaml"]
    resources += [f"{s.module}.yaml" for s in services]
    resources += ["frontend.yaml", "ingress.yaml"]
    files["kustomization.yaml"] = (
        "apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\n"
        f"namespace: {project}\n"
        "resources:\n" + "".join(f"  - {r}\n" for r in resources) + "\n"
        "# To use a remote registry, uncomment and adapt:\n"
        "# images:\n"
        f"#   - name: {project}/api-gateway\n"
        "#     newName: registry.example.com/team/api-gateway\n"
        f"#     newTag: {IMAGE_TAG}\n"
    )
    return files


# --- tables and diagrams for the documentation ------------------------------------------------
def doc_tokens(services: list[Service]) -> dict[str, str]:
    first = services[0]
    mermaid_services, mermaid_kafka = [], []
    for s in services:
        i = s.index
        mermaid_services.append(f"  gw --> s{i}[{s.module}<br/>:{s.port}]")
        mermaid_services.append(f"  s{i} --> d{i}[({s.db})]")
        mermaid_services.append(f"  s{i} -.-> eureka")
        mermaid_services.append(f"  cfg -.-> s{i}")
    mermaid_kafka.append("  kafka{{Kafka}}")
    mermaid_kafka.append(f"  s0 -->|{first.topic}| kafka")
    for s in services[1:]:
        mermaid_kafka.append(f"  kafka -->|{first.topic}| s{s.index}")

    services_table = ["| Module | Port | Route (through gateway) | Database | Published topic | Consumed topic |",
                      "|---|---|---|---|---|---|"]
    for s in services:
        consumed = "—" if s is first else f"`{first.topic}`"
        services_table.append(
            f"| `{s.module}` | {s.port} | `/api/{s.resource}/**` | `{s.db}` | `{s.topic}` | {consumed} |")

    topics_table = ["| Topic | Producer | Consumers | Partitions | Key |", "|---|---|---|---|---|"]
    for s in services:
        consumers = ", ".join(f"`{c.module}`" for c in services[1:]) if s is first else "_none yet_"
        if s is first and len(services) == 1:
            consumers = "_none yet_"
        topics_table.append(f"| `{s.topic}` | `{s.module}` | {consumers} | 3 | aggregate UUID |")

    db_table = ["| Database | Owning service | Initial table |", "|---|---|---|"]
    for s in services:
        db_table.append(f"| `{s.db}` | `{s.module}` | `{s.table}` (migration `V1__init.sql`) |")

    return {
        "MERMAID_SERVICES": "\n".join(mermaid_services),
        "MERMAID_KAFKA": "\n".join(mermaid_kafka),
        "SERVICES_TABLE": "\n".join(services_table),
        "TOPICS_TABLE": "\n".join(topics_table),
        "DATABASES_TABLE": "\n".join(db_table),
        "RESOURCES_TS": "[\n" + "".join(
            f"    {{ label: '{s.label}', path: '{s.resource}' }},\n" for s in services) + "  ]",
    }


# --- main program -----------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", required=True, help="project name in kebab-case (e.g. shopflow)")
    parser.add_argument("--title", help="readable title (default: derived from the name)")
    parser.add_argument("--domain", default="Microservices application", help="business domain in one sentence")
    parser.add_argument("--group-id", help="Java groupId (default: com.example.<project>)")
    parser.add_argument("--services", default="order:8081,notification:8082",
                        help="comma-separated list of name[:port][:w=role+role][:r=role+role]; "
                             "the first service publishes, the others consume; w = roles allowed to write, "
                             "r = read-only roles (default: 1st role writes, the others read)")
    parser.add_argument("--roles", default="admin,user",
                        help="Keycloak realm roles, comma-separated (e.g. dispatcher,merchant,courier,customer)")
    parser.add_argument("--out", help="output folder (default: ./<project>)")
    parser.add_argument("--force", action="store_true", help="allow writing into a non-empty folder")
    args = parser.parse_args()

    if not KEBAB.match(args.project):
        fail("--project must be kebab-case (lowercase letters, digits, hyphens; starts with a letter)")
    title = args.title or args.project.replace("-", " ").title()
    for label, value in (("--title", title), ("--domain", args.domain)):
        if re.search(r"[\"'\\&<>]", value):
            fail(f"{label} must not contain quotes, backslashes, & < > (the text goes into XML/TS/YAML)")
    group_id = args.group_id or f"com.example.{args.project.replace('-', '')}"
    if not re.match(r"^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$", group_id):
        fail("invalid --group-id (e.g. com.acme.shopflow, lowercase, at least two segments)")

    specs = [x for x in args.services.split(",") if x.strip()]
    if not specs:
        fail("--services cannot be empty")
    roles = [r.strip() for r in args.roles.split(",") if r.strip()]
    if not roles or len(set(roles)) != len(roles) or not all(re.match(r"^[a-z][a-z0-9_-]*$", r) for r in roles):
        fail("--roles: non-empty list of unique lowercase names (letters, digits, - or _)")
    realm = args.project
    client_id = f"{realm}-frontend"
    services = [Service(spec, i, group_id, roles) for i, spec in enumerate(specs)]
    names = [s.name for s in services]
    if len(set(names)) != len(names):
        fail("duplicate service names")
    ports = {}
    for s in services:
        if s.port in RESERVED_PORTS:
            fail(f"port {s.port} already used by {RESERVED_PORTS[s.port]}")
        if s.port in ports:
            fail(f"port {s.port} used by {ports[s.port]} and {s.module}")
        ports[s.port] = s.module

    out = Path(args.out or args.project).resolve()
    if out.exists() and any(out.iterdir()) and not args.force:
        fail(f"{out} is not empty (use --force to write anyway)")
    out.mkdir(parents=True, exist_ok=True)

    date = datetime.date.today().isoformat()
    group_path = group_id.replace(".", "/")
    first, last = services[0], services[-1]
    modules_xml = "\n".join(
        f"    <module>{m}</module>" for m in
        ["config-server", "discovery-server", "api-gateway"] + [f"services/{s.module}" for s in services])

    base = {
        "PROJECT": args.project, "PROJECT_TITLE": title, "GROUP_ID": group_id, "DOMAIN": args.domain,
        "DOMAIN_XML": html.escape(args.domain), "DATE": date,
        "SPRING_BOOT_VERSION": SPRING_BOOT_VERSION, "SPRING_CLOUD_VERSION": SPRING_CLOUD_VERSION,
        "MODULES": modules_xml, "FIRST_RESOURCE": first.resource, "LAST_SERVICE": last.module,
        **doc_tokens(services),
        **security_tokens(services, roles, realm, client_id),
    }

    w = Writer(out)
    w.copy_tree(ASSETS / "root", "", base)
    w.copy_tree(ASSETS / "docs", "docs", base)
    w.write("docs/adr/README.md", render_index(date))
    for i, adr in enumerate(ADRS, start=1):
        w.write(f"docs/adr/ADR-{i:04d}.md", render_adr(i, adr, date))
    w.copy_tree(ASSETS / "frontend", "frontend", base)

    logback = (ASSETS / "modules" / "logback-spring.xml.tpl").read_text(encoding="utf-8")
    for module, sub in (("config-server", "config"), ("discovery-server", "discovery"), ("api-gateway", "gateway")):
        tokens = {**base, "PACKAGE": f"{group_id}.{sub}"}
        w.copy_tree(ASSETS / "modules" / module, module, tokens, {"PKG": f"{group_path}/{sub}"})
        w.write(f"{module}/src/main/resources/logback-spring.xml", render(logback, tokens))

    for name, content in config_repo(services, realm).items():
        w.write(f"config-server/src/main/resources/config-repo/{name}", content)

    for s in services:
        tokens = {
            **base, "PACKAGE": s.package, "SERVICE": s.module, "PORT": str(s.port), "ENTITY": s.entity,
            "RESOURCE": s.resource, "TABLE": s.table, "TOPIC": s.topic,
            "SOURCE_SERVICE": first.module, "SOURCE_ENTITY": first.entity, "SOURCE_TOPIC": first.topic,
        }
        names = {"PKG": f"{group_path}/{s.pkg}", "ENTITY": s.entity, "SOURCE_ENTITY": first.entity}
        dest = f"services/{s.module}"
        w.copy_tree(ASSETS / "service", dest, tokens, names)
        w.write(f"{dest}/src/main/resources/logback-spring.xml", render(logback, tokens))
        if s is not first:
            w.copy_tree(ASSETS / "service-consumer", dest, tokens, names)

    init_sql = init_db_sql(services)
    w.write("infra/docker/init-db.sql", init_sql)
    realm_doc = keycloak_realm(realm, client_id, roles)
    w.write("infra/keycloak/realm.json", realm_doc)
    w.write("docker-compose.yml", compose(args.project, services, realm))
    w.write("Makefile", makefile(args.project, services))
    logstash_conf = (out / "infra/elk/logstash/pipeline/logstash.conf").read_text(encoding="utf-8")
    for name, content in k8s_manifests(args.project, services, init_sql, logstash_conf, realm, realm_doc).items():
        w.write(f"k8s/{name}", content)

    # Check: no unresolved token.
    leftovers = []
    for f in w.files:
        rel = f.relative_to(out).as_posix()
        if re.search(r"__[A-Z_]+__", rel):
            leftovers.append(f"path: {rel}")
        text = f.read_text(encoding="utf-8")
        for m in re.finditer(r"@@[A-Z_]+@@", text):
            leftovers.append(f"{rel}: {m.group(0)}")
    if leftovers:
        print("Unresolved tokens:\n  " + "\n  ".join(leftovers), file=sys.stderr)
        sys.exit(2)

    print(f"OK: {len(w.files)} files generated in {out}")
    print(f"  groupId     : {group_id}")
    print("  services    : " + ", ".join(f"{s.module}:{s.port}" for s in services))
    print(f"  keycloak    : realm '{realm}', roles {', '.join(roles)} (dev accounts: see docs/architecture/06-security.md)")
    print("  Kafka flow  : " + f"{first.module} -> {first.topic} -> " + ", ".join(s.module for s in services[1:]) if len(services) > 1 else "  Kafka flow  : (single service, no consumer)")
    print("Next step: write docs/product/ and docs/sprints/ (see references/agile-docs.md).")


if __name__ == "__main__":
    main()
