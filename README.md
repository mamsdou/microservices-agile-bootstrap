# microservices-agile-bootstrap

**Un skill [Claude Code](https://claude.com/claude-code) (et un générateur Python autonome) qui met en place en une commande une application en architecture microservices — Spring Boot 3 / Java 21, Spring Cloud, Angular 15, Kafka, PostgreSQL, ELK, Keycloak, Docker, Kubernetes — avec une documentation de projet claire, organisée selon Scrum.**

> **English summary** — Generates a runnable microservices skeleton (Spring Boot 3 + Java 21, Spring Cloud Config/Eureka/Gateway, Angular 15, Kafka, PostgreSQL one-DB-per-service, ELK, Keycloak OIDC/JWT with role-based access, Docker Compose, Kubernetes/kustomize, GitHub Actions CI) plus ready-to-use Scrum documentation (ADRs, Definition of Ready/Done, architecture docs, product backlog guidance). Use it as a Claude Code skill, or run `scripts/scaffold.py` directly with Python 3.10+. Generated docs are in French. See [Limitations](#limites-et-ce-qui-a-été-vérifié).

---

## À quoi ça sert

Démarrer un projet microservices demande des jours de plomberie avant la première ligne de code métier : parent Maven, Config Server, registre, passerelle, bases de données, bus d'événements, logs centralisés, authentification, conteneurs, manifests Kubernetes, CI… puis il faut documenter tout cela et organiser le travail en sprints.

Ce skill fait les deux :

1. **Un squelette exécutable et cohérent** (générateur déterministe, toujours le même résultat pour les mêmes paramètres).
2. **Une documentation prête pour une équipe agile** : décisions d'architecture (ADR), Definition of Ready / Done, charte Scrum, stratégie de test, et — rédigés par Claude à partir de votre domaine métier — vision produit, roadmap, product backlog en user stories, Sprint 0 / Sprint 1, registre des risques.

## Ce qui est généré

```
mon-projet/
├── pom.xml                  # parent Maven : Java 21, Spring Boot 3.3, Spring Cloud 2023.0
├── config-server/           # configuration centralisée (config-repo/ : un fichier par service)
├── discovery-server/        # registre Eureka
├── api-gateway/             # point d'entrée unique, exige un JWT valide sur /api/**
├── services/<nom>-service/  # un microservice par domaine : REST, JPA + Flyway, Kafka, sécurité par rôle
├── frontend/                # Angular 15 + connexion OIDC (nginx en conteneur)
├── infra/                   # Dockerfile Java, pipeline Logstash, init PostgreSQL, realm Keycloak
├── k8s/                     # manifests Kubernetes (kustomize)
├── docker-compose.yml       # PostgreSQL, Kafka (KRaft), Kafka UI, ELK, Keycloak + les services
├── .github/workflows/ci.yml # build Maven + Angular, validation compose/k8s
└── docs/                    # architecture, ADR, agile, qualité (+ produit et sprints rédigés par Claude)
```

Détails de chaque microservice généré :

- API REST `GET`/`POST /api/<ressource>` avec validation, accès par rôle (401 / 403), tests unitaires et tests de sécurité ;
- une **base PostgreSQL par service**, schéma versionné avec Flyway ;
- publication d'un événement Kafka **après commit** (`@TransactionalEventListener`), consommation idempotente à compléter ;
- logs JSON envoyés vers Logstash → Elasticsearch → Kibana ;
- sondes de santé (Actuator) prêtes pour Kubernetes.

## Prérequis

| Pour… | Il faut |
|---|---|
| utiliser le skill | [Claude Code](https://claude.com/claude-code) (ou toute application Claude qui prend en charge les skills) |
| lancer le générateur seul | Python **3.10+** (aucune dépendance externe) |
| construire le projet généré | JDK 21, Maven 3.9+, Node 18 (Angular 15), Docker |
| lancer toute la stack en local | Docker avec environ **6 à 8 Go de RAM** disponibles |

## Installation

### Comme skill Claude Code

```bash
git clone https://github.com/mamsdou/microservices-agile-bootstrap.git
cp -r microservices-agile-bootstrap/microservices-agile-bootstrap ~/.claude/skills/
```

Sous Windows (PowerShell) :

```powershell
git clone https://github.com/mamsdou/microservices-agile-bootstrap.git
Copy-Item -Recurse microservices-agile-bootstrap\microservices-agile-bootstrap $env:USERPROFILE\.claude\skills\
```

Pour limiter le skill à un projet, copiez le dossier dans `<projet>/.claude/skills/` à la place. Redémarrez Claude Code : le skill est détecté automatiquement.

### Sans Claude (générateur seul)

Le dossier `microservices-agile-bootstrap/scripts/scaffold.py` fonctionne tout seul. Dans ce cas seule la partie technique et les documents d'architecture/agile « génériques » sont produits ; les documents produit (vision, backlog…) restent à écrire.

## Utilisation

### Avec Claude Code

Décrivez simplement votre projet, par exemple :

> « Mets en place une application de livraison en microservices avec Spring Cloud, Angular, Kafka, PostgreSQL, Keycloak, Docker et Kubernetes, et la documentation Scrum. »

Claude déduit les services et les rôles de votre domaine, lance le générateur, rédige les documents produit (vision, roadmap, backlog en user stories avec critères d'acceptation, Sprint 0/1, risques), puis vérifie ce qui peut l'être (compose, kustomize, build Maven/Angular) et vous dit honnêtement ce qui ne l'a pas été.

### Avec le script

```bash
python microservices-agile-bootstrap/scripts/scaffold.py \
  --project livraison --title "Livraison" \
  --domain "Application de livraison : commande, affectation de livreurs, suivi" \
  --group-id com.exemple.livraison \
  --roles dispatcher,merchant,courier,customer \
  --services "order:8081:w=merchant+dispatcher:r=customer,delivery:8082:w=dispatcher+courier:r=merchant,courier:8083:w=dispatcher+courier,notification:8084:w=dispatcher:r=customer" \
  --out ./livraison
```

| Option | Rôle |
|---|---|
| `--project` | Nom du projet en kebab-case (sert aussi de nom de realm Keycloak) |
| `--title` / `--domain` | Titre lisible et description du domaine métier en une phrase |
| `--group-id` | `groupId` Java (défaut `com.example.<projet>`) |
| `--roles` | Rôles Keycloak du realm, séparés par des virgules (défaut `admin,user`) |
| `--services` | `nom[:port][:w=role+role][:r=role+role]` séparés par des virgules. `w` = rôles autorisés à écrire (et lire), `r` = rôles en lecture seule. Le **premier** service publie sur Kafka, les suivants consomment |
| `--out` | Dossier de sortie ; refuse d'écraser un dossier non vide sauf `--force` |

Puis, dans le projet généré :

```bash
docker compose up -d --build     # stack complète
```

| Élément | URL |
|---|---|
| Application Angular | http://localhost:4200 |
| API Gateway | http://localhost:8080 |
| Keycloak | http://localhost:8180 |
| Eureka / Config Server | http://localhost:8761 / http://localhost:8888 |
| Kibana / Kafka UI | http://localhost:5601 / http://localhost:8090 |

Les comptes de **développement** (un par rôle) sont listés dans `docs/architecture/06-securite.md` du projet généré.

## Documentation agile produite

| Dossier | Contenu |
|---|---|
| `docs/adr/` | 10 décisions d'architecture (microservices, Spring Cloud, base par service, Kafka, publication après commit, ELK, Angular, Docker/K8s, monorepo, Keycloak) |
| `docs/architecture/` | Vue d'ensemble (diagramme Mermaid), services et ports, événements Kafka, données, observabilité, déploiement, sécurité |
| `docs/agile/` | Definition of Ready, Definition of Done, charte d'équipe (rôles, cérémonies, estimation) |
| `docs/qualite/` | Stratégie de test |
| `docs/produit/` et `docs/sprints/` | Vision, roadmap, product backlog, risques, Sprint 0 et 1 — **rédigés par Claude** selon [`references/agile-docs.md`](microservices-agile-bootstrap/references/agile-docs.md) |

## Limites et ce qui a été vérifié

Soyons transparents sur l'état actuel (version 0.1) :

- ✅ Vérifié : le générateur (plusieurs configurations, cas d'erreur), `docker compose config` et `kubectl kustomize` sur les fichiers générés, `mvn verify` (tests unitaires et de sécurité) et `ng build` en production, le Config Server et la passerelle sécurisée démarrés pour de vrai (401 sans jeton, santé en 200, CORS).
- ⚠️ **Non vérifié** : le démarrage complet de la stack Docker, le **démarrage de Keycloak** (import du realm, healthcheck, URL d'émetteur `KC_HOSTNAME`), le parcours de connexion Angular de bout en bout, et la compilation sous **JDK 21** (la vérification a été faite avec un JDK 17 en surchargeant `java.version`). Si vous les validez, une issue ou une PR est la bienvenue.
- Le squelette est un **point de départ** : l'entité générée par service (nom, date) est volontairement générique, les consommateurs Kafka se contentent de journaliser, Keycloak tourne en mode développement (base H2, HTTP) et les secrets sont des valeurs de dev. Voir « À durcir avant la production » dans les docs générées.
- Les rôles protègent l'accès aux ressources mais pas la **propriété des données** (un utilisateur voit tout ce que son rôle peut lire) : à traiter par story métier.
- Angular 15 n'est plus supporté activement ; les versions (Spring Boot 3.3.5 / Spring Cloud 2023.0.3, Keycloak 25, Elastic 8.15…) sont regroupées en tête de `scaffold.py` et se mettent à jour ensemble.
- Les documents générés sont en français.

## Personnaliser

- **Versions** : constantes en tête de [`scripts/scaffold.py`](microservices-agile-bootstrap/scripts/scaffold.py).
- **Code, infra et docs générés** : modèles dans [`assets/`](microservices-agile-bootstrap/assets) (suffixe `.tpl`, jetons `@@NOM@@` dans les fichiers, `__NOM__` dans les chemins).
- **Décisions d'architecture** : [`scripts/adrs.py`](microservices-agile-bootstrap/scripts/adrs.py).
- **Comportement de Claude** (questions posées, vérifications, rédaction du backlog) : [`SKILL.md`](microservices-agile-bootstrap/SKILL.md) et [`references/`](microservices-agile-bootstrap/references).

## Structure du dépôt

```
.
├── README.md
├── LICENSE
└── microservices-agile-bootstrap/   # le skill (à copier dans ~/.claude/skills/)
    ├── SKILL.md                     # instructions pour Claude
    ├── scripts/                     # scaffold.py (générateur) et adrs.py
    ├── assets/                      # modèles du code, de l'infra et des docs
    └── references/                  # structure des documents produit, repères d'architecture
```

## Contribuer

Les issues et pull requests sont les bienvenues, en particulier : retours de test sous JDK 21 et sur la stack Docker complète, autres stacks (Gradle, Angular récent, Keycloak en production), et traductions des documents générés.

## Licence

[MIT](LICENSE)
