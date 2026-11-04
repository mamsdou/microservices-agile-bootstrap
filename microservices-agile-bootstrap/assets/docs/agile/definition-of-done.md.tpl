# Definition of Done (DoD)

Un élément du backlog est « Terminé » seulement si **tout** ce qui suit est vrai. La DoD est commune à l'équipe et s'applique à chaque incrément.

## Code
- [ ] Code relu (Pull Request approuvée par au moins une autre personne).
- [ ] Respecte les règles d'architecture de `CONTRIBUTING.md` (un service = ses données, contrats rétrocompatibles).
- [ ] Aucune alerte critique d'analyse statique ; pas de secret dans le dépôt.

## Tests
- [ ] Tests unitaires ajoutés/mis à jour et verts (`mvn -B verify`).
- [ ] Tests d'intégration pour les nouveaux contrats (REST, Kafka) quand pertinent.
- [ ] Critères d'acceptation de la story vérifiés, par une personne autre que l'auteur ou automatiquement.
- [ ] Build front OK (`ng build`) si le front est touché.

## Livraison
- [ ] Pipeline CI vert sur la branche.
- [ ] Déployable : l'image Docker se construit et la stack démarre (`docker compose up`).
- [ ] Migrations Flyway ajoutées si le schéma change (jamais de modification d'une migration appliquée).
- [ ] Logs exploitables dans Kibana pour le nouveau comportement.

## Documentation
- [ ] ADR créé si une décision d'architecture a été prise.
- [ ] Docs `docs/` mises à jour (contrats d'API, événements, schéma) et README à jour.
- [ ] Story démontrable lors de la revue de sprint.
