# Architecture générée : repères pour modifier ou étendre

## Sommaire
- Vue d'ensemble
- Versions et compatibilité
- Conventions de nommage
- Flux de configuration
- Ajouter un service
- Pièges connus

## Vue d'ensemble

```
Navigateur → frontend (nginx :4200) → api-gateway (:8080) → services métier (:8081…)
                                            │                    │        │
                                       discovery (:8761)    PostgreSQL   Kafka (KRaft)
                                       config-server (:8888)  (1 base / service)
Logs JSON (TCP :5000) → Logstash → Elasticsearch → Kibana (:5601)
```

Le premier service métier publie `<service>.events` ; les suivants consomment ce topic (groupe = nom du service). C'est un exemple de flux à remplacer par les vrais événements du domaine.

## Versions et compatibilité

Définies en tête de `scripts/scaffold.py` : Spring Boot 3.3.5 ↔ Spring Cloud 2023.0.3 (ce couple est compatible ; Spring Cloud 2024.0 exige Boot 3.4 et change le préfixe des propriétés Gateway en `spring.cloud.gateway.server.webflux`). Angular 15.2 exige Node 14.20, 16 ou 18 (le Dockerfile utilise Node 18). Elastic 8.15, Kafka 3.8 (image `apache/kafka`), PostgreSQL 16. Si tu changes Boot, change Spring Cloud avec lui et vérifie la table de compatibilité officielle.

## Conventions de nommage

Pour un service `user-profile` : module `user-profile-service`, classe `UserProfile`, ressource REST `/api/user-profiles`, table `user_profiles`, base `user_profile_db`, topic `user-profile.events`, package `<groupId>.userprofile`.

## Flux de configuration

Chaque module a un `application.yml` local minimal (nom, port, import du Config Server en `optional:`). Tout le reste vient de `config-server/src/main/resources/config-repo/` (`application.yml` partagé, `<service>.yml`, `api-gateway.yml`). En production, remplacer le backend `native` par un dépôt Git (ADR-0002). Les placeholders `${VAR:défaut}` des fichiers du config-repo sont résolus côté client : c'est ce qui permet d'avoir les mêmes fichiers en local, Compose et Kubernetes.

## Ajouter un service

Relancer le script avec `--force` écraserait le dossier : préférer copier un service existant (`services/<x>-service`), renommer package/classes/table/migration, puis mettre à jour : `<parent>/pom.xml` (modules), `config-repo/<nouveau>.yml`, `config-repo/api-gateway.yml` (route), `infra/docker/init-db.sql`, `docker-compose.yml`, `k8s/` (nouveau fichier + `kustomization.yaml`), `frontend/src/app/app.component.ts` (liste `resources`), `docs/architecture/` et l'ADR si le service apporte une décision structurante.

## Sécurité (Keycloak)

- Realm = nom du projet, client public `<projet>-frontend` (code + PKCE), un utilisateur de dev par rôle (mot de passe `dev-<rôle>`, uniquement pour le local). Le realm est généré par `scaffold.py` (`keycloak_realm`) dans `infra/keycloak/realm.json`, importé par `start-dev --import-realm`.
- Gateway (WebFlux) : `authenticated()` sur `/api/**`. Services (servlet) : `SecurityConfig` + `KeycloakRoleConverter` (`realm_access.roles` → `ROLE_<nom>`), droits lus dans `app.security.write-roles` / `read-roles` du `config-repo`. Un rôle d'écriture lit aussi.
- Le claim d'émetteur doit être identique pour le navigateur et les services : Keycloak est lancé avec `KC_HOSTNAME=http://localhost:8180`, les services valident `iss` avec `KEYCLOAK_ISSUER` mais lisent les clés avec `KEYCLOAK_JWKS` (adresse interne `http://keycloak:8080`). Si les jetons sont rejetés (401) alors qu'ils sont valides, vérifier ce point en premier.
- Angular : `angular-oauth2-oidc` ; `frontend/src/config.js` (URL Keycloak, realm, client) est surchargeable sans reconstruire l'image (ConfigMap `frontend-config` en Kubernetes).
- Les rôles ne protègent pas la propriété des données (un client voit tout ce que son rôle lit) : prévoir une story dédiée basée sur le claim `sub`.
- Ajouter un service ou un rôle : relancer la logique du script ou éditer à la main `realm.json` (rôles, utilisateurs), le `config-repo/<service>.yml` (rôles) et `docs/architecture/06-securite.md`.

## Pièges connus

- Keycloak (image `quay.io/keycloak/keycloak:25.0.6`) n'a pas pu être lancé lors de la conception du skill (Docker indisponible) : le healthcheck du Compose, `KC_HOSTNAME` et l'import du realm sont à valider au premier démarrage.

- Flyway 10 (Boot 3.3) exige `flyway-database-postgresql` en plus de `flyway-core` : déjà dans les POM.
- Un service qui démarre avant le Config Server n'a ni datasource ni Kafka : le Compose utilise `depends_on … service_healthy` ; en local hors Docker, démarrer config-server puis discovery-server d'abord.
- Les événements sont publiés après commit (`@TransactionalEventListener`), mais sans garantie si le broker est indisponible à ce moment : l'Outbox pattern est la suite logique (ADR-0005, story de backlog).
- Elasticsearch en dev tourne sans sécurité (`xpack.security.enabled=false`) : à ne pas exposer.
- Les secrets Kubernetes générés sont des valeurs de dev encodées, pas du chiffrement.
