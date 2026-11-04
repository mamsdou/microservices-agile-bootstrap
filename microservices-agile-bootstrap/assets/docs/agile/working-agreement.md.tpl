# Charte de fonctionnement Scrum

## Rôles

| Rôle | Responsabilités | Titulaire |
|---|---|---|
| Product Owner | Porte la vision, ordonne le Product Backlog, accepte les stories | _à définir_ |
| Scrum Master | Garant du cadre Scrum, lève les obstacles, facilite les cérémonies | _à définir_ |
| Équipe de développement | Conçoit, développe, teste et livre l'incrément ; auto-organisée | _à définir_ |

## Rythme

- **Sprint** de 2 semaines (à ajuster après le Sprint 1) ; objectif de sprint commun, périmètre négociable, qualité non négociable.
- Un **incrément** potentiellement livrable (DoD respectée) à la fin de chaque sprint.

## Cérémonies

| Cérémonie | Quand | Durée max | Objectif |
|---|---|---|---|
| Sprint Planning | 1er jour | 2 h | Choisir l'objectif et les stories (DoR), découper en tâches |
| Daily Scrum | Chaque jour | 15 min | Se synchroniser sur l'objectif de sprint, signaler les blocages |
| Backlog Refinement | Mi-sprint | 1 h | Clarifier, découper et estimer les prochaines stories |
| Sprint Review | Dernier jour | 1 h | Démonstration de l'incrément, retours des parties prenantes |
| Rétrospective | Dernier jour | 1 h | Une amélioration concrète et suivie pour le sprint suivant |

## Estimation

Story points (suite de Fibonacci) en planning poker, relatifs à une story de référence choisie par l'équipe. La vélocité (points terminés par sprint) sert à planifier, jamais à comparer des personnes ou des équipes.

## Indicateurs suivis

Vélocité, burndown de sprint, taux de stories respectant la DoR, nombre de défauts échappés, délai entre commit et mise en production (lead time), temps de build CI.

## Accords d'équipe

- Une seule source de vérité : le Product Backlog et le board du sprint.
- On limite le travail en cours : finir avant de commencer.
- Les décisions d'architecture se prennent en équipe et s'écrivent (ADR).
- Les blocages se remontent le jour même.
