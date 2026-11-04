# Documents produit Scrum : structure attendue

Rédige en français, concis, orienté décision. Un document agile qui n'est pas relu ne sert à rien : privilégie les tableaux et listes courtes.

## Sommaire
- vision.md
- roadmap.md
- product-backlog.md
- sprint-0.md
- sprint-1-planning.md
- risques.md
- Exemple de user story

---

## docs/produit/vision.md

```
# Vision produit — <Titre>
## Énoncé de vision        (1 phrase : Pour <cible> qui <besoin>, <produit> est un <catégorie> qui <bénéfice>. Contrairement à <alternative>, notre produit <différenciation>.)
## Contexte et problème    (3–5 lignes)
## Personas                (tableau : persona | objectif | frustration actuelle)
## Objectifs et indicateurs (tableau : objectif | KPI mesurable | cible | échéance)
## Périmètre               (Inclus / Hors périmètre de la v1)
## Contraintes et hypothèses
## Parties prenantes       (rôle | nom ou « à définir » | attente)
```

## docs/produit/roadmap.md

Releases par valeur, pas par composant technique. 3 à 4 jalons, chacun avec objectif, épics visées, priorité MoSCoW (Must/Should/Could/Won't) et critère de sortie. Rappeler que la roadmap est un plan d'intention, révisé à chaque revue de sprint.

## docs/produit/product-backlog.md

Structure :
1. **Conventions** : identifiants `EP-01` (épic) / `US-001` (story), estimation en story points (Fibonacci 1-2-3-5-8-13), priorité MoSCoW, statut (À faire / Prêt / En cours / Terminé). Une story > 8 points est découpée.
2. **Tableau récapitulatif** : id | titre | épic | priorité | points | statut | service(s) concerné(s)
3. **Détail par épic** : objectif, puis chaque story au format ci-dessous.
4. **Stories techniques (enablement)** : traçabilité des fondations (CI, observabilité, sécurité). Les formuler avec une valeur (« afin de pouvoir déployer sans régression »), pas comme des tâches.

Critères de qualité d'une story (INVEST) : Indépendante, Négociable, apportant de la Valeur, Estimable, Small, Testable.

## Exemple de user story

```
### US-004 — Passer une commande
**En tant que** client connecté **je veux** valider mon panier **afin de** recevoir mes articles.
- Épic : EP-02 Commande · Priorité : Must · Estimation : 5 · Service(s) : order, notification
- Critères d'acceptation :
  - Étant donné un panier non vide, quand je valide, alors une commande au statut CREATED est enregistrée et son identifiant m'est renvoyé.
  - Étant donné une commande créée, alors un événement `order.events` est publié et une notification est enregistrée.
  - Étant donné un panier vide, quand je valide, alors je reçois une erreur 400 explicite.
- Notes techniques : publication après commit ; pas d'appel synchrone vers notification.
- Dépendances : US-002
```

## docs/sprints/sprint-0.md

Objectif : « Un incrément déployable de bout en bout existe ». Tableau des éléments déjà fournis par le squelette (cocher ✅ : parent POM, config/discovery/gateway, services avec REST+JPA+Kafka, front Angular, docker-compose, ELK, manifests K8s, CI, authentification Keycloak et rôles) et de ce qui reste (⬜ : propriété des données, durcissement de Keycloak, environnements, jeux de données, pipeline de déploiement). Termine par la Definition of Done de Sprint 0 et la date de fin.

## docs/sprints/sprint-1-planning.md

- Durée (2 semaines par défaut), dates, capacité de l'équipe (à renseigner : nb de personnes × jours)
- **Objectif de sprint** : une phrase orientée valeur utilisateur (ex. « Un client peut créer une commande et voir sa confirmation »)
- **Sprint backlog** : 4 à 6 stories issues du haut du backlog, conformes à la Definition of Ready (voir `docs/agile/definition-of-ready.md`), total de points ≤ vélocité supposée (si inconnue, 20–25 pour une petite équipe, à recaler après le sprint)
- Découpage en tâches par story (facultatif mais utile)
- Risques et dépendances connus du sprint
- Rappel des événements : daily, revue, rétrospective (dates)

## docs/produit/risques.md

Tableau : id | risque | probabilité (F/M/E) | impact (F/M/E) | mitigation | propriétaire | statut. Inclure au moins : complexité opérationnelle des microservices pour une petite équipe, cohérence éventuelle des données entre services, consommation mémoire de la stack ELK/Kafka en local, accès aux données d'autrui (le squelette applique les rôles mais pas la propriété des données) et Keycloak en mode dev, dépendances des versions (Angular 15 hors support LTS).
