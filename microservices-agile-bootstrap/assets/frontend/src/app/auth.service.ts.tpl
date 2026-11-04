import { Injectable } from '@angular/core';
import { OAuthService } from 'angular-oauth2-oidc';

import { buildAuthConfig } from './auth.config';

/** Connexion OIDC (Keycloak) : l'access token est ajoute aux appels /api par OAuthModule. */
@Injectable({ providedIn: 'root' })
export class AuthService {
  roles: string[] = [];
  unavailable = false;

  constructor(private readonly oauth: OAuthService) {}

  /** Appele au demarrage de l'application. Ne bloque jamais l'affichage si Keycloak est injoignable. */
  async init(): Promise<void> {
    this.oauth.configure(buildAuthConfig());
    this.oauth.events.subscribe((event) => {
      if (event.type === 'token_received') {
        this.roles = this.readRoles();
      }
    });
    try {
      await this.oauth.loadDiscoveryDocumentAndTryLogin();
      if (this.isLoggedIn) {
        this.roles = this.readRoles();
        this.oauth.setupAutomaticSilentRefresh();
      }
    } catch (error) {
      console.warn('Authentification indisponible', error);
      this.unavailable = true;
    }
  }

  get isLoggedIn(): boolean {
    return this.oauth.hasValidAccessToken();
  }

  get username(): string {
    const claims = this.oauth.getIdentityClaims() as Record<string, unknown> | null;
    return String(claims?.['preferred_username'] ?? '');
  }

  login(): void {
    this.oauth.initCodeFlow();
  }

  logout(): void {
    this.oauth.logOut();
  }

  /** Lit les roles de realm dans l'access token (affichage uniquement : l'autorisation est faite cote serveur). */
  private readRoles(): string[] {
    const token = this.oauth.getAccessToken();
    if (!token) {
      return [];
    }
    try {
      const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
      return payload?.realm_access?.roles ?? [];
    } catch {
      return [];
    }
  }
}
