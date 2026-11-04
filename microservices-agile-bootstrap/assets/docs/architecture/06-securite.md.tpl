# 06 — Sécurité : authentification et autorisation

Décision : [ADR-0010](../adr/ADR-0010.md) — Keycloak (OIDC) et jetons JWT.

## Principe

```mermaid
sequenceDiagram
  participant B as Navigateur (Angular)
  participant K as Keycloak
  participant G as API Gateway
  participant S as Microservice
  B->>K: 1. Connexion (code d'autorisation + PKCE)
  K-->>B: 2. Access token JWT (rôles dans realm_access.roles)
  B->>G: 3. GET/POST /api/... + Authorization: Bearer <jwt>
  G->>G: 4. Vérifie signature, émetteur, expiration
  G->>S: 5. Relaie la requête avec le jeton
  S->>S: 6. Revérifie le jeton et contrôle le rôle
  S-->>B: 7. Réponse (200, 401 ou 403)
```

- **Keycloak** (realm `@@KEYCLOAK_REALM@@`, client public `@@KEYCLOAK_CLIENT_ID@@`) authentifie l'utilisateur et émet les jetons. Aucun secret n'est stocké dans le navigateur (flux *authorization code* avec PKCE).
- **La gateway** refuse toute requête `/api/**` sans jeton valide (401). Elle ne connaît pas les règles métier.
- **Chaque service** valide lui-même le jeton (un appel direct à un service, sans passer par la gateway, est donc aussi protégé) et applique la matrice de rôles ci-dessous (403 si le rôle ne suffit pas). Les rôles viennent de la configuration centralisée (`config-repo/<service>.yml`, clés `app.security.*`).

## Rôles et matrice d'accès

Rôles du realm : @@ROLES_LIST@@.

@@SECURITY_MATRIX@@

Les rôles d'écriture peuvent aussi lire. Pour changer une règle, modifier `app.security.write-roles` / `app.security.read-roles` dans le `config-repo` du service puis redémarrer le service (ou activer le rafraîchissement de configuration). Les tests `*ControllerSecurityTest` vérifient le comportement 401 / 403 / succès de chaque service.

## Comptes de développement

Importés au démarrage de Keycloak depuis `infra/keycloak/realm.json`. **Uniquement pour le développement local** : ils ne doivent jamais exister en production.

@@DEV_USERS_TABLE@@

Console d'administration Keycloak : http://localhost:8180 (compte administrateur de dev défini dans `.env.example`).

## Obtenir un jeton en ligne de commande (dev)

```bash
TOKEN=$(curl -s http://localhost:8180/realms/@@KEYCLOAK_REALM@@/protocol/openid-connect/token \
  -d grant_type=password -d client_id=@@KEYCLOAK_CLIENT_ID@@ \
  -d username=@@FIRST_WRITER@@ -d password=dev-@@FIRST_WRITER@@ | jq -r .access_token)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/@@FIRST_RESOURCE@@
```

Le flux « password » (`directAccessGrantsEnabled`) n'est activé que pour ce confort de développement.

## Points d'attention techniques

- **Émetteur (`iss`) et adresses** : le navigateur joint Keycloak sur `http://localhost:8180`, les services le joignent sur `http://keycloak:8080`. Keycloak est donc configuré avec `KC_HOSTNAME=http://localhost:8180` pour que `iss` soit toujours le même ; les services valident `iss` avec `KEYCLOAK_ISSUER` (par défaut l'URL publique) mais lisent les clés de signature via `KEYCLOAK_JWKS` (adresse interne).
- **Kubernetes** : Keycloak est exposé au navigateur par `kubectl port-forward svc/keycloak 8180:8080` ; avec un vrai Ingress/TLS, adapter `KC_HOSTNAME`, `KEYCLOAK_ISSUER`, `frontend-config` et passer `requireHttps` à `true` (`frontend/src/app/auth.config.ts`).
- Les rôles affichés par l'interface servent à l'affichage ; **l'autorisation est toujours faite côté serveur**.

## Reste à faire avant la production

- Remplacer Keycloak `start-dev` (base H2 embarquée) par un déploiement durable : base PostgreSQL dédiée, HTTPS, réplicas, sauvegardes.
- Désactiver le flux « password », supprimer les comptes de dev, définir politique de mots de passe, MFA et durée des jetons.
- Gérer la propriété des données (un client ne doit voir que **ses** objets) : les rôles seuls ne le garantissent pas ; à traiter par story, via le claim `sub` du jeton.
- Identités de service à service (appels backend) : *client credentials* avec un client Keycloak confidentiel.
- Journaliser les accès refusés et alerter sur les échecs répétés (Kibana).
