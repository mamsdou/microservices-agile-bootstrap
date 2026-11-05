# 06 — Security: authentication and authorization

Decision: [ADR-0010](../adr/ADR-0010.md) — Keycloak (OIDC) and JWT tokens.

## Principle

```mermaid
sequenceDiagram
  participant B as Browser (Angular)
  participant K as Keycloak
  participant G as API Gateway
  participant S as Microservice
  B->>K: 1. Login (authorization code + PKCE)
  K-->>B: 2. JWT access token (roles in realm_access.roles)
  B->>G: 3. GET/POST /api/... + Authorization: Bearer <jwt>
  G->>G: 4. Checks signature, issuer, expiry
  G->>S: 5. Forwards the request with the token
  S->>S: 6. Rechecks the token and the role
  S-->>B: 7. Response (200, 401 or 403)
```

- **Keycloak** (realm `@@KEYCLOAK_REALM@@`, public client `@@KEYCLOAK_CLIENT_ID@@`) authenticates the user and issues tokens. No secret is stored in the browser (*authorization code* flow with PKCE).
- **The gateway** rejects any `/api/**` request without a valid token (401). It knows no business rules.
- **Each service** validates the token itself (a direct call that bypasses the gateway is therefore also protected) and applies the role matrix below (403 if the role is insufficient). Roles come from centralized configuration (`config-repo/<service>.yml`, `app.security.*` keys).

## Roles and access matrix

Realm roles: @@ROLES_LIST@@.

@@SECURITY_MATRIX@@

Write roles can also read. To change a rule, edit `app.security.write-roles` / `app.security.read-roles` in the service's `config-repo` file, then restart the service (or enable configuration refresh). The `*ControllerSecurityTest` tests check the 401 / 403 / success behavior of each service.

## Development accounts

Imported at Keycloak startup from `infra/keycloak/realm.json`. **For local development only**: they must never exist in production.

@@DEV_USERS_TABLE@@

Keycloak admin console: http://localhost:8180 (dev admin account defined in `.env.example`).

## Getting a token from the command line (dev)

```bash
TOKEN=$(curl -s http://localhost:8180/realms/@@KEYCLOAK_REALM@@/protocol/openid-connect/token \
  -d grant_type=password -d client_id=@@KEYCLOAK_CLIENT_ID@@ \
  -d username=@@FIRST_WRITER@@ -d password=dev-@@FIRST_WRITER@@ | jq -r .access_token)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/@@FIRST_RESOURCE@@
```

The "password" flow (`directAccessGrantsEnabled`) is enabled only for this development convenience.

## Technical notes

- **Issuer (`iss`) and addresses**: the browser reaches Keycloak at `http://localhost:8180`, services reach it at `http://keycloak:8080`. Keycloak is therefore configured with `KC_HOSTNAME=http://localhost:8180` so `iss` is always the same; services validate `iss` with `KEYCLOAK_ISSUER` (public URL by default) but read signing keys through `KEYCLOAK_JWKS` (internal address).
- **Kubernetes**: Keycloak is exposed to the browser with `kubectl port-forward svc/keycloak 8180:8080`; with a real Ingress/TLS, adapt `KC_HOSTNAME`, `KEYCLOAK_ISSUER` and `frontend-config`, and set `requireHttps` to `true` (`frontend/src/app/auth.config.ts`).
- Roles shown by the UI are for display only; **authorization is always done on the server side**.

## To do before production

- Replace Keycloak `start-dev` (embedded H2 database) with a durable deployment: dedicated PostgreSQL database, HTTPS, replicas, backups.
- Disable the "password" flow, remove dev accounts, define password policy, MFA and token lifetimes.
- Handle data ownership (a customer must see only **their** objects): roles alone do not guarantee this; handle it per story using the token's `sub` claim.
- Service-to-service identities (backend calls): *client credentials* with a confidential Keycloak client.
- Log denied access and alert on repeated failures (Kibana).
