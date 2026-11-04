---
name: microservices-agile-bootstrap
description: Met en place une application en architecture microservices (Spring Boot 3 / Java 21, Spring Cloud Config-Eureka-Gateway, Angular 15, Kafka, PostgreSQL, stack ELK, Docker, Kubernetes) avec un squelette exécutable ET une documentation de projet claire selon Scrum (vision produit, roadmap, product backlog en user stories, DoR/DoD, sprint 0/1, ADR, docs d'architecture). À utiliser dès que l'utilisateur veut démarrer, initialiser, bootstrapper ou structurer un projet microservices Spring/Angular/Kafka, parle d'architecture microservices avec Spring Cloud, de squelette de projet, de documentation agile / Scrum / backlog / user stories pour un tel projet, ou d'infra docker-compose + Kubernetes + ELK, même s'il ne dit pas le mot « skill ».
---

# Microservices + documentation agile : bootstrap

Ce skill produit en une passe un dépôt cohérent : **code exécutable**, **infra** (Docker, Kubernetes, ELK, Kafka, PostgreSQL) et **documentation Scrum** adaptée au métier de l'utilisateur. La partie technique est générée par un script déterministe (`scripts/scaffold.py`) pour que le squelette soit toujours le même et qu'il démarre ; la partie produit (vision, backlog, sprints) est rédigée par toi, car elle dépend du domaine.

Stack figée (ne pas la rediscuter, l'utilisateur l'a choisie) : Java 21, Maven multi-modules, Spring Boot 3.3 + Spring Cloud 2023.0 (Config Server, Eureka, Gateway), Angular 15, Kafka (KRaft), PostgreSQL 16 (une base par service), ELK 8 (Logstash TCP), Docker Compose, Kubernetes (kustomize), authentification Keycloak (OIDC/JWT, rôles par service). Documentation en français.

## Déroulé

### 1. Recueillir les paramètres (poser peu de questions)

Il te faut : un **nom de projet** (kebab-case, ex. `shopflow`), un **domaine métier** en une phrase, un **groupId** Java (défaut `com.example.<projet>`), la liste des **microservices métier** (défaut : 2) et les **rôles utilisateurs** du domaine (ex. client, livreur, commerçant, administrateur ; défaut `admin,user`). Pour chaque service, déduis qui peut écrire et qui peut seulement lire (`:w=role+role:r=role`) ; sans cela le premier rôle écrit et les autres lisent, ce qui est rarement juste. Si l'utilisateur ne précise pas le domaine, propose-en un plausible et continue, ne bloque pas. Déduis les services du domaine (ex. e-commerce → `catalog`, `order`, `notification`) ; le premier publie des événements Kafka, les suivants les consomment — choisis donc l'ordre pour que ça ait un sens métier.

Dossier de sortie : si la session n'a pas de dossier de projet, génère dans le répertoire courant sous `<nom-projet>/`.

### 2. Générer le squelette technique

```bash
python <skill>/scripts/scaffold.py --project shopflow --title "ShopFlow" \
  --domain "Plateforme e-commerce" --group-id com.acme.shopflow \
  --roles admin,merchant,customer \
  --services "catalog:8081:w=admin+merchant:r=customer,order:8082:w=customer+admin:r=merchant,notification:8083:w=admin" \
  --out ./shopflow
```

Ce qui est produit : parent POM + `config-server`, `discovery-server`, `api-gateway`, un module par service métier (API REST, JPA/Flyway, publication Kafka après commit, consommation Kafka, logs JSON vers Logstash, test unitaire), `frontend/` Angular 15 (+ nginx, connexion OIDC), Keycloak (realm importé `infra/keycloak/realm.json` avec un compte de dev par rôle ; gateway et services valident le JWT et appliquent les rôles de `config-repo/<service>.yml` ; tests 401/403 par service), `docker-compose.yml`, `k8s/` (kustomize), CI GitHub Actions, `Makefile`, et `docs/architecture/` + `docs/adr/` + `docs/agile/` + `docs/qualite/` déjà renseignés avec les ports, topics et services réels. Lis `references/architecture.md` si tu dois modifier ou étendre le squelette (ajouter un service, changer une version, comprendre un choix).

Le script refuse d'écraser un dossier non vide sauf `--force`.

### 3. Rédiger les documents produit Scrum

Le script ne les écrit pas, volontairement : ils doivent parler du métier de l'utilisateur. Lis `references/agile-docs.md` (structure attendue de chaque document, exemples de user stories INVEST avec critères Gherkin) puis écris dans `docs/produit/` et `docs/sprints/` :

- `vision.md` — vision produit, personas, objectifs mesurables, périmètre / hors périmètre
- `roadmap.md` — releases et jalons (priorisation MoSCoW)
- `product-backlog.md` — épics → user stories (valeur, critères d'acceptation, estimation, priorité), dont les stories techniques d'enablement
- `sprint-0.md` — « fondations » : ce que le squelette généré couvre déjà (cocher) et ce qui reste
- `sprint-1-planning.md` — objectif de sprint et sprint backlog réaliste
- `risques.md` — registre des risques et dépendances

Chaque story doit tenir debout seule : « En tant que… je veux… afin de… », critères d'acceptation vérifiables, taille. Relie les stories aux services du squelette (un service = un propriétaire de données), sans quoi le backlog et l'architecture divergent dès la semaine 1.

Mets à jour `docs/README.md` (index) pour lier ces nouveaux documents, et complète la section « Contexte » du `README.md` racine avec la vision en 3 lignes.

### 4. Vérifier avant de rendre la main

- `docker compose config -q` dans le dossier généré (valide le YAML et les variables)
- `kubectl kustomize k8s` ou `kubectl apply -k k8s --dry-run=client` si `kubectl` est disponible
- `mvn -B verify` si Maven est disponible. Le projet cible Java 21 ; avec un JDK 17 local, ajoute `-Djava.version=17` (le code n'utilise aucune API 21) pour vérifier compilation et tests unitaires, et dis clairement que la compilation sous Java 21 n'a pas été exécutée
- `npm install && npx ng build --configuration production` dans `frontend/` si Node est disponible (testé avec Node 22 : fonctionne)
- relire l'arborescence : aucun `@@…@@` ni `__…__` résiduel (`grep -r "@@" .`)

Annonce honnêtement ce qui a été vérifié et ce qui ne l'a pas été (ex. compilation Java 21, démarrage complet de la stack).

### 5. Résumer à l'utilisateur

Arborescence en quelques lignes, commandes pour démarrer (`docker compose up -d --build`, URLs : frontend :4200, gateway :8080, Eureka :8761, Kibana :5601, Kafka UI :8090), et les 3 prochaines étapes naturelles (démarrer Sprint 1, restreindre l'accès aux données par propriétaire, mettre en place l'Outbox pattern). Signale que le parcours de connexion Keycloak n'est vérifié que par tests unitaires et un test de la gateway tant que la stack Docker n'a pas été lancée. Le compose complet demande environ 6–8 Go de RAM : préviens-en l'utilisateur.

## Principes à respecter

- **Une base de données par service**, jamais de jointure inter-services : c'est ce qui rend les services réellement indépendants, et le backlog doit refléter cette frontière.
- **Pas de secrets réels** dans le dépôt : les valeurs par défaut sont des valeurs de dev, signalées comme telles ; la prod passe par des secrets Kubernetes / un coffre.
- **Les décisions sont tracées en ADR** (`docs/adr/`). Si l'utilisateur change un choix (ex. Gradle, Keycloak), ajoute un ADR qui remplace l'ancien plutôt que de réécrire l'historique.
- **Increment = valeur** : Sprint 0 ne doit pas durer plus d'un sprint ; le squelette existe pour que le Sprint 1 livre une première tranche verticale (front → gateway → service → base → Kafka).
