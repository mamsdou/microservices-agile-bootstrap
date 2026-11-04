# 04 — Observabilité

## Chaîne de logs

```
Service Spring (profil "elk") → Logstash :5000 (TCP, JSON lines) → Elasticsearch → Kibana
```

- Chaque module embarque `logstash-logback-encoder` et un `logback-spring.xml` : avec le profil Spring `elk`, les logs partent en JSON vers Logstash **et** restent sur la console (`docker logs`).
- Le champ `app` (nom du service) est ajouté à chaque événement ; Logstash en déduit l'index `logs-<app>-AAAA.MM.JJ`.
- Configuration : `infra/elk/logstash/pipeline/logstash.conf`. Variable `LOGSTASH_HOST` pour cibler un autre hôte.

## Utiliser Kibana

1. Ouvrir http://localhost:5601 → *Stack Management* → *Data Views* → créer la vue `logs-*` avec `@timestamp` comme champ temporel.
2. *Discover* : filtrer par `app`, `level`, `message`.
3. Pour suivre une requête à travers les services, ajouter un identifiant de corrélation (à planifier : Micrometer Tracing / OpenTelemetry).

## Santé et métriques

Spring Actuator expose `/actuator/health` (sondes liveness/readiness pour Kubernetes). Les métriques Prometheus ne sont pas encore activées (cf. backlog).

## Avertissements de sécurité

Elasticsearch tourne **sans authentification** en dev (`xpack.security.enabled=false`). Ne jamais l'exposer en dehors de la machine locale ; en production, activer la sécurité Elastic et TLS.

## Ressources

La stack ELK complète consomme de la mémoire (Elasticsearch 512 Mo de heap + Logstash + Kibana). Sur une machine limitée, ne démarrer que les services utiles : `docker compose up -d --build postgres kafka config-server discovery-server api-gateway <services> frontend`, et retirer le profil `elk` (variable `SPRING_PROFILES_ACTIVE`).
