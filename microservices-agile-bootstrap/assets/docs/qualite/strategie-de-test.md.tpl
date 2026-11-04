# Stratégie de test

## Pyramide

| Niveau | Outil | Portée | Fréquence |
|---|---|---|---|
| Unitaire | JUnit 5, Mockito, AssertJ | Logique de service/domaine, sans réseau ni base | Chaque commit (CI) |
| Intégration | Spring Boot Test + Testcontainers (PostgreSQL, Kafka) | Persistance, migrations Flyway, production/consommation d'événements | Chaque PR |
| Contrat | Spring Cloud Contract ou Pact | API REST et schémas d'événements entre services | Chaque PR touchant un contrat |
| Bout en bout | Cypress/Playwright sur la stack Compose | Parcours critiques de l'interface | Avant release |

Le squelette fournit un test unitaire par service ; les niveaux supérieurs sont des stories d'enablement du backlog.

## Règles

- Tester le comportement (critères d'acceptation), pas l'implémentation.
- Les tests sont indépendants, déterministes et rapides ; pas de dépendance à l'ordre d'exécution.
- Pas d'appel à un autre service réel dans un test unitaire.
- Un bug corrigé = un test qui l'aurait détecté.

## Environnements de test

Les tests d'intégration utilisent des conteneurs éphémères (Testcontainers) : pas de base partagée. Les jeux de données sont créés par le test lui-même.

## Seuils indicatifs

Couverture de lignes ≥ 70 % sur la logique métier (indicateur, pas objectif en soi) ; zéro test ignoré sans ticket associé.
