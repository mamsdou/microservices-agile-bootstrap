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

/** Merges the defaults with window.APP_CONFIG (config.js file, editable at deployment). */
export function buildAuthConfig(): AuthConfig {
  const runtime = (window as unknown as { APP_CONFIG?: Partial<AppConfig> }).APP_CONFIG ?? {};
  const cfg = { ...defaults, ...runtime };
  return {
    issuer: `${cfg.keycloakUrl}/realms/${cfg.realm}`,
    clientId: cfg.clientId,
    redirectUri: window.location.origin,
    // "Authorization code" + PKCE flow: no secret in the browser.
    responseType: 'code',
    scope: 'openid profile email',
    // HTTP allowed for local development only: set to true behind HTTPS.
    requireHttps: false,
    showDebugInformation: false,
  };
}
