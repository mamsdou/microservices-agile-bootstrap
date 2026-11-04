import { AuthConfig } from 'angular-oauth2-oidc';

interface AppConfig {
  keycloakUrl: string;
  realm: string;
  clientId: string;
}

const defaults: AppConfig = {
  keycloakUrl: 'http://localhost:8180',
  realm: '@@KEYCLOAK_REALM@@',
  clientId: '@@KEYCLOAK_CLIENT_ID@@',
};

/** Fusionne les valeurs par defaut avec window.APP_CONFIG (fichier config.js, modifiable au deploiement). */
export function buildAuthConfig(): AuthConfig {
  const runtime = (window as unknown as { APP_CONFIG?: Partial<AppConfig> }).APP_CONFIG ?? {};
  const cfg = { ...defaults, ...runtime };
  return {
    issuer: `${cfg.keycloakUrl}/realms/${cfg.realm}`,
    clientId: cfg.clientId,
    redirectUri: window.location.origin,
    // Flux "authorization code" + PKCE : pas de secret cote navigateur.
    responseType: 'code',
    scope: 'openid profile email',
    // HTTP autorise pour le developpement local uniquement : passer a true derriere HTTPS.
    requireHttps: false,
    showDebugInformation: false,
  };
}
