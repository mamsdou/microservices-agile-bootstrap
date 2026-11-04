# 02 — Événements Kafka

## Catalogue des topics

@@TOPICS_TABLE@@

## Format des messages

- Clé : identifiant de l'agrégat (UUID en chaîne) — garantit l'ordre par agrégat au sein d'une partition.
- Valeur : JSON UTF-8.

```json
{ "id": "6f1c…", "name": "exemple", "occurredAt": "2026-01-01T10:00:00Z" }
```

## Règles

1. **Contrat public** : un événement est un contrat entre équipes. On ajoute des champs optionnels ; on ne renomme ni ne supprime sans nouvelle version de topic.
2. **Livraison au moins une fois** : les consommateurs sont **idempotents** (déduplication sur l'`id` d'événement ou opération naturellement idempotente).
3. **Publication après commit** (`@TransactionalEventListener(AFTER_COMMIT)`) : jamais d'événement pour une donnée annulée. Limite : perte possible si Kafka est indisponible à cet instant → Outbox pattern à planifier (ADR-0005).
4. **Groupe de consommation** = nom du service ; plusieurs instances d'un même service se partagent les partitions.
5. **Erreurs de traitement** : prévoir un topic `<topic>.dlt` (dead letter) avant la mise en production.

## Pour inspecter

Kafka UI : http://localhost:8090 (topics, messages, groupes de consommateurs).
