# 01 — Services et ports

## Services d'infrastructure

| Module | Rôle | Port | Santé |
|---|---|---|---|
| `config-server` | Configuration centralisée (`config-repo/`, backend `native`) | 8888 | `/actuator/health` |
| `discovery-server` | Registre Eureka | 8761 | `/actuator/health` |
| `api-gateway` | Point d'entrée unique, routage `/api/<ressource>/**`, CORS | 8080 | `/actuator/health` |

## Services métier

@@SERVICES_TABLE@@

Chaque service expose `GET`/`POST /api/<ressource>`, valide ses entrées, persiste via JPA/Flyway et publie un événement `<service>.events` après commit. Les services suivant le premier consomment les événements du premier (exemple de flux à remplacer par les vrais cas d'usage). L'entité générée par service (nom, date de création) est un **point de départ** à renommer et enrichir selon le domaine.

## Autres composants

| Composant | Port(s) | Usage |
|---|---|---|
| Frontend (nginx) | 4200 → 80 | Application Angular, relaie `/api` vers la gateway |
| PostgreSQL | 5432 | Une base par service |
| Kafka | 9092 (interne), 29092 (hôte) | Bus d'événements |
| Kafka UI | 8090 | Inspection des topics |
| Keycloak | 8180 → 8080 | Authentification OIDC, émission des JWT (voir `06-securite.md`) |
| Elasticsearch | 9200 | Stockage des logs |
| Logstash | 5000 | Réception TCP des logs JSON |
| Kibana | 5601 | Exploration des logs |

## Règles d'évolution

- Ajouter un service : voir `references/architecture.md` du skill, puis un ADR si une décision structurante est prise.
- Les ports ci-dessus sont des valeurs par défaut surchargeables via la variable `SERVER_PORT`.
