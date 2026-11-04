"""Architecture Decision Records (format Michael Nygard) générés avec le squelette.

Chaque entrée décrit une décision déjà matérialisée dans le code généré. Les textes sont
volontairement courts : l'équipe les complète avec son contexte réel.
"""

ADRS = [
    {
        "title": "Architecture microservices",
        "context": (
            "Le produit doit évoluer par domaines métier indépendants, avec des équipes pouvant "
            "livrer sans coordination lourde. Un monolithe modulaire serait plus simple au début, "
            "mais l'organisation cible et la scalabilité différenciée des fonctions justifient "
            "des services séparés."
        ),
        "decision": (
            "Découper le système en microservices métier autonomes (un service = un contexte "
            "borné, ses données, son cycle de livraison), derrière une API Gateway. "
            "Chaque service est une application Spring Boot 3 / Java 21."
        ),
        "consequences": (
            "+ Déploiement et scalabilité indépendants, frontières de domaine explicites.\n"
            "- Complexité opérationnelle (réseau, observabilité, cohérence éventuelle).\n"
            "- Nécessité d'outillage (CI/CD, supervision) dès le début : couvert par ce squelette.\n"
            "Révision possible : regrouper des services si le découpage s'avère trop fin."
        ),
    },
    {
        "title": "Spring Cloud : Config Server, Eureka, Gateway",
        "context": (
            "Il faut externaliser la configuration, localiser dynamiquement les instances et "
            "offrir un point d'entrée unique (routage, CORS, futur contrôle d'accès)."
        ),
        "decision": (
            "Utiliser Spring Cloud Config Server (backend `native` en dev, fichiers dans "
            "`config-server/src/main/resources/config-repo`), Eureka pour la découverte et "
            "Spring Cloud Gateway pour le routage `lb://<service>`. Les placeholders "
            "`${VAR:défaut}` sont résolus côté client, ce qui garde les mêmes fichiers en local, "
            "Compose et Kubernetes."
        ),
        "consequences": (
            "+ Un seul endroit pour la configuration ; services interchangeables.\n"
            "- Config Server et Eureka deviennent des composants critiques au démarrage.\n"
            "- En production : passer le Config Server sur un dépôt Git chiffré et évaluer la "
            "découverte native de Kubernetes pour retirer Eureka (nouvel ADR le cas échéant)."
        ),
    },
    {
        "title": "Une base PostgreSQL par service",
        "context": (
            "Partager un schéma entre services recrée un couplage fort et empêche des "
            "déploiements indépendants."
        ),
        "decision": (
            "Chaque service possède sa base logique PostgreSQL (`<service>_db`), versionnée avec "
            "Flyway, avec Hibernate en `validate`. Aucun accès inter-bases ; échanges par API ou "
            "événements."
        ),
        "consequences": (
            "+ Autonomie, évolutions de schéma sans impact sur les autres services.\n"
            "- Pas de jointures ni de transactions multi-services : cohérence éventuelle, sagas.\n"
            "- En dev une seule instance héberge toutes les bases (coût réduit)."
        ),
    },
    {
        "title": "Apache Kafka pour la communication asynchrone",
        "context": (
            "Les services doivent réagir aux faits métier des autres sans appels synchrones "
            "enchaînés (fragiles et couplés dans le temps)."
        ),
        "decision": (
            "Utiliser Kafka (mode KRaft, sans ZooKeeper) comme bus d'événements. Un topic "
            "`<service>.events` par service producteur, messages JSON clés par identifiant "
            "d'agrégat, groupe de consommation = nom du service."
        ),
        "consequences": (
            "+ Découplage temporel, relecture possible, montée en charge par partitions.\n"
            "- Consommateurs obligatoirement idempotents (livraison au moins une fois).\n"
            "- Gouvernance des contrats d'événements nécessaire (voir docs/architecture/02)."
        ),
    },
    {
        "title": "Publication des événements après commit, Outbox en cible",
        "context": (
            "Publier sur Kafka dans la transaction métier n'est pas atomique : on peut publier "
            "un événement pour des données finalement annulées, ou l'inverse."
        ),
        "decision": (
            "Publier via `@TransactionalEventListener(AFTER_COMMIT)` : aucun événement pour une "
            "transaction annulée. Accepter pour l'instant la perte possible si Kafka est "
            "indisponible juste après le commit, et planifier le pattern Transactional Outbox "
            "(table `outbox` + relais) dans le backlog."
        ),
        "consequences": (
            "+ Simple, sans dépendance supplémentaire, suffisant pour démarrer.\n"
            "- Garantie de livraison partielle tant que l'Outbox n'est pas en place : "
            "à traiter avant tout flux critique (paiement, facturation)."
        ),
    },
    {
        "title": "Observabilité avec la stack ELK via Logstash TCP",
        "context": (
            "Diagnostiquer un incident dans un système distribué impose de centraliser les logs "
            "avec un format structuré."
        ),
        "decision": (
            "Chaque service émet des logs JSON (`logstash-logback-encoder`) vers Logstash (TCP "
            "5000) avec le profil Spring `elk`, en plus de la console. Logstash alimente "
            "Elasticsearch (index `logs-<app>-<date>`), exploré dans Kibana 8."
        ),
        "consequences": (
            "+ Mise en place simple, pas d'agent à déployer sur les nœuds.\n"
            "- Perte de logs si Logstash est indisponible (reconnexion, pas de tampon disque).\n"
            "- Sécurité Elastic désactivée en dev ; consommation mémoire notable.\n"
            "À évaluer plus tard : Filebeat/Elastic Agent, traces distribuées OpenTelemetry."
        ),
    },
    {
        "title": "Frontend Angular 15 servi par nginx",
        "context": (
            "L'interface web doit être découplée des services et déployable comme un artefact "
            "statique."
        ),
        "decision": (
            "Application Angular 15 (NgModule, HttpClient) construite en image multi-étapes puis "
            "servie par nginx, qui relaie `/api` vers la gateway (même origine, pas de CORS en "
            "conteneur). En développement `ng serve` utilise un proxy vers :8080."
        ),
        "consequences": (
            "+ Image légère, configuration identique en Compose et Kubernetes.\n"
            "- Angular 15 n'est plus supporté activement : prévoir une montée de version "
            "(story technique) avant la mise en production."
        ),
    },
    {
        "title": "Conteneurisation Docker et déploiement Kubernetes (kustomize)",
        "context": (
            "Il faut un environnement de dev reproductible et une cible de production "
            "orchestrée."
        ),
        "decision": (
            "Une image Java générique (`infra/docker/Dockerfile.java`, build Maven multi-étapes, "
            "utilisateur non root), un `docker-compose.yml` pour le poste de dev et des manifests "
            "Kubernetes assemblés par kustomize (sondes Actuator, ressources, ConfigMap/Secret)."
        ),
        "consequences": (
            "+ Parité dev/prod, déploiement déclaratif.\n"
            "- L'infrastructure de données (Postgres, Kafka, Elasticsearch) est en instance "
            "unique : à remplacer par des opérateurs ou services managés en production.\n"
            "- Les secrets de dev ne conviennent pas à la production."
        ),
    },
    {
        "title": "Monorepo Maven multi-modules",
        "context": (
            "Une petite équipe démarre ; séparer immédiatement un dépôt par service multiplierait "
            "la charge de coordination (versions, revues, CI)."
        ),
        "decision": (
            "Un seul dépôt avec un POM parent (Java 21, BOM Spring Boot et Spring Cloud) et un "
            "module par service ; `frontend/` et `infra/` dans le même dépôt. CI unique."
        ),
        "consequences": (
            "+ Refactorings transverses simples, versions alignées, onboarding rapide.\n"
            "- Le pipeline doit éviter de tout reconstruire à chaque changement (builds "
            "incrémentaux à prévoir).\n"
            "Découpable en plusieurs dépôts plus tard si l'organisation l'exige."
        ),
    },
    {
        "title": "Authentification et autorisation avec Keycloak (OIDC) et JWT",
        "context": (
            "L'API ne doit être accessible qu'à des utilisateurs identifiés, avec des droits "
            "différents selon leur rôle. Écrire un serveur d'identité maison est coûteux et risqué."
        ),
        "decision": (
            "Utiliser Keycloak comme fournisseur d'identité (OpenID Connect). Le frontend Angular "
            "se connecte par le flux code d'autorisation + PKCE (client public, sans secret). "
            "La gateway et chaque service sont des « resource servers » : ils valident le JWT "
            "(signature par JWKS, émetteur, expiration). Les rôles de realm (`realm_access.roles`) "
            "deviennent des autorités Spring (`ROLE_<nom>`) ; chaque service déclare ses rôles "
            "d'écriture et de lecture dans la configuration centralisée (`app.security.*`). "
            "Le jeton est relayé par la gateway ; les services le revalident (défense en profondeur)."
        ),
        "consequences": (
            "+ Standards ouverts, SSO, comptes et rôles gérés hors du code, aucun mot de passe "
            "manipulé par nos services.\n"
            "+ Un service appelé directement reste protégé.\n"
            "- Keycloak devient un composant critique à exploiter (le mode `start-dev` fourni ne "
            "convient pas à la production : base dédiée, HTTPS, haute disponibilité).\n"
            "- Les rôles ne suffisent pas pour la propriété des données (un client ne voit que ses "
            "objets) : à traiter métier par métier via le claim `sub`.\n"
            "- L'URL de l'émetteur doit être identique pour le navigateur et les services "
            "(voir docs/architecture/06-securite.md)."
        ),
    },
]


def render_adr(number: int, adr: dict, date: str) -> str:
    return (
        f"# ADR-{number:04d} — {adr['title']}\n\n"
        f"- **Statut** : Accepté\n"
        f"- **Date** : {date}\n\n"
        f"## Contexte\n\n{adr['context']}\n\n"
        f"## Décision\n\n{adr['decision']}\n\n"
        f"## Conséquences\n\n{adr['consequences']}\n"
    )


def render_index(date: str) -> str:
    lines = [
        "# Décisions d'architecture (ADR)",
        "",
        "Format : [Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions). "
        "Un ADR n'est jamais réécrit : pour changer une décision, ajouter un nouvel ADR qui "
        "la remplace et passer l'ancien au statut « Remplacé par ADR-XXXX ».",
        "",
        "| N° | Titre | Statut |",
        "|---|---|---|",
    ]
    for i, adr in enumerate(ADRS, start=1):
        lines.append(f"| [ADR-{i:04d}](ADR-{i:04d}.md) | {adr['title']} | Accepté |")
    lines.append("")
    return "\n".join(lines)
