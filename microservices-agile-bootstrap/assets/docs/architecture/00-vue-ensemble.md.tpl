# 00 — Vue d'ensemble

## Contexte

@@DOMAIN@@

## Diagramme de conteneurs (C4 niveau 2)

```mermaid
flowchart LR
  user([Utilisateur]) --> fe[Frontend Angular 15<br/>nginx]
  fe -->|/api + JWT| gw[API Gateway<br/>Spring Cloud Gateway]
  user -.->|connexion OIDC| kc[(Keycloak)]
  gw -.->|clés JWKS| kc
  gw -.->|découverte| eureka[(Eureka)]
@@MERMAID_SERVICES@@
  cfg[Config Server] -.->|configuration| gw
@@MERMAID_KAFKA@@
  apps[[Tous les services Spring]] -.->|logs JSON| ls[Logstash] --> es[(Elasticsearch)] --> kb[Kibana]
```

## Stack technique

| Couche | Choix | Référence |
|---|---|---|
| Langage / framework | Java 21, Spring Boot @@SPRING_BOOT_VERSION@@ | ADR-0001 |
| Cloud-native | Spring Cloud @@SPRING_CLOUD_VERSION@@ : Config, Eureka, Gateway | ADR-0002 |
| Données | PostgreSQL 16, une base par service, Flyway | ADR-0003 |
| Messagerie | Apache Kafka (KRaft) | ADR-0004, ADR-0005 |
| Observabilité | Logstash, Elasticsearch, Kibana 8.x | ADR-0006 |
| Frontend | Angular 15 servi par nginx | ADR-0007 |
| Déploiement | Docker, Docker Compose, Kubernetes (kustomize) | ADR-0008 |
| Build | Maven multi-modules, monorepo | ADR-0009 |
| Sécurité | Keycloak (OIDC), JWT, rôles par service | ADR-0010 |

## Principes directeurs

1. **Autonomie des services** : chaque service possède ses données et se déploie seul.
2. **Événements pour découpler** : un service publie des faits métier, les autres réagissent.
3. **Configuration externalisée** : le même artefact tourne partout, seul l'environnement change.
4. **Observable par défaut** : logs structurés, santé exposée, corrélation par service.
5. **Décisions tracées** : tout choix structurant fait l'objet d'un ADR.

## Hors périmètre de la version initiale

Autorisation par propriétaire des données (rôles seulement pour l'instant), durcissement de Keycloak pour la production, métriques applicatives (Prometheus/Grafana), traçage distribué, Outbox pattern, haute disponibilité des composants d'infrastructure. Ces sujets sont à planifier dans le backlog.
