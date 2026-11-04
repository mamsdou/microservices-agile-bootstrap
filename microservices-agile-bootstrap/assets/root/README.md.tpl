# @@PROJECT_TITLE@@

> @@DOMAIN@@

Application en architecture **microservices** : Spring Boot 3 / Java 21, Spring Cloud (Config, Eureka, Gateway), Angular 15, Kafka, PostgreSQL, ELK, Docker et Kubernetes. Projet piloté en **Scrum** (voir `docs/`).

## Contexte

_À compléter : vision en 3 lignes (voir `docs/produit/vision.md`)._

## Démarrage rapide

Prérequis : Docker (avec ~6-8 Go de RAM disponibles pour la stack complète). Pour développer sans Docker : JDK 21, Maven 3.9+, Node 18.

```bash
docker compose up -d --build
```

| Élément | URL |
|---|---|
| Application (Angular) | http://localhost:4200 |
| API Gateway | http://localhost:8080 |
| Eureka (registre) | http://localhost:8761 |
| Config Server | http://localhost:8888 |
| Kibana (logs) | http://localhost:5601 |
| Kafka UI | http://localhost:8090 |
| Keycloak (authentification) | http://localhost:8180 |

L'API est protégée : il faut un jeton JWT. Dans l'interface (http://localhost:4200), cliquer sur « Se connecter » (comptes de développement : voir [`docs/architecture/06-securite.md`](docs/architecture/06-securite.md)). Rôles du realm : @@ROLES_LIST@@.

Premier test de bout en bout en ligne de commande (nécessite `jq`) :

```bash
TOKEN=$(curl -s http://localhost:8180/realms/@@KEYCLOAK_REALM@@/protocol/openid-connect/token \
  -d grant_type=password -d client_id=@@KEYCLOAK_CLIENT_ID@@ \
  -d username=@@FIRST_WRITER@@ -d password=dev-@@FIRST_WRITER@@ | jq -r .access_token)
curl -X POST http://localhost:8080/api/@@FIRST_RESOURCE@@ -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"name":"demo"}'
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/@@FIRST_RESOURCE@@
```

Puis observer la réaction du consommateur : `docker compose logs -f @@LAST_SERVICE@@`, ou dans Kibana (vue de données `logs-*`).

## Structure

```
@@PROJECT@@/
├── pom.xml                  # parent Maven (Java 21, Spring Boot, Spring Cloud)
├── config-server/           # configuration centralisée (config-repo/)
├── discovery-server/        # registre Eureka
├── api-gateway/             # point d'entrée unique
├── services/                # microservices métier (une base PostgreSQL chacun)
├── frontend/                # Angular 15 (servi par nginx)
├── infra/                   # Dockerfile Java, Logstash, init PostgreSQL
├── k8s/                     # manifests Kubernetes (kustomize)
├── docker-compose.yml
└── docs/                    # produit, agile, architecture, ADR, qualité
```

## Documentation

Index complet : [`docs/README.md`](docs/README.md). Pour contribuer : [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Commandes utiles

| Commande | Effet |
|---|---|
| `mvn -B verify` | build + tests de tous les modules |
| `docker compose up -d --build` / `down` | démarrer / arrêter la stack |
| `make images` | construire les images Docker locales |
| `kubectl apply -k k8s` | déployer sur Kubernetes (voir `docs/architecture/05-deploiement.md`) |
