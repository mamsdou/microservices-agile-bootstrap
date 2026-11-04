# Guide de contribution

## Flux de travail Git

- Branche principale `main` toujours déployable ; travail dans des branches courtes `feature/US-123-titre-court`, `fix/…`, `chore/…`.
- Une **Pull Request** par user story (ou par partie indépendante d'une story), relue par au moins une personne, CI verte.
- Rebase ou squash avant fusion pour garder un historique lisible.

## Messages de commit (Conventional Commits)

`type(portée): résumé à l'impératif` — types : `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`.
Exemple : `feat(order): publier un événement après création (US-004)`.

## Avant d'ouvrir une PR

1. La story respecte la [Definition of Ready](docs/agile/definition-of-ready.md) et la PR la [Definition of Done](docs/agile/definition-of-done.md).
2. `mvn -B verify` passe ; `npx ng build` passe si le front est touché.
3. Toute décision d'architecture notable est consignée dans un ADR (`docs/adr/`, numéro suivant).
4. Les contrats entre services (API REST, événements Kafka) changent de façon rétrocompatible, ou sont versionnés.

## Règles d'architecture

- Un service = ses données : pas d'accès direct à la base d'un autre service.
- Communication synchrone via la gateway/REST, asynchrone via Kafka ; consommateurs idempotents.
- Aucune valeur secrète dans le dépôt.
