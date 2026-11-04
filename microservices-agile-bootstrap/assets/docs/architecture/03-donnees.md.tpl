# 03 — Données

## Principe : une base par service

Une seule instance PostgreSQL 16 en développement, mais **une base logique par service** ; en production, chaque base peut être déplacée sur sa propre instance sans changer le code.

@@DATABASES_TABLE@@

## Règles

- Aucun service n'accède à la base d'un autre ; on échange par API ou par événements. Pas de jointure ni de clé étrangère inter-services.
- Le schéma est versionné avec **Flyway** (`src/main/resources/db/migration/V<n>__description.sql`). Une migration déjà appliquée n'est jamais modifiée : on en ajoute une nouvelle.
- Hibernate est en `ddl-auto: validate` : le schéma ne change que par migration.
- Les identifiants sont des UUID générés par l'application (pas de séquence partagée, facilite la réplication et les événements).
- Le compte `postgres` partagé est réservé au développement. En production : un rôle par service avec droits restreints à sa base, identifiants dans un coffre / Secret Kubernetes.

## Cohérence entre services

La cohérence est **éventuelle** : un service reflète l'état d'un autre en consommant ses événements. Pour une opération couvrant plusieurs services, privilégier une saga par événements plutôt qu'une transaction distribuée.
