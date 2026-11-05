// Frontend runtime configuration. Can be overridden without rebuilding the image
// (Docker volume or Kubernetes ConfigMap mounted on /usr/share/nginx/html/config.js).
window.APP_CONFIG = {
  keycloakUrl: 'http://localhost:8180',
  realm: '@@KEYCLOAK_REALM@@',
  clientId: '@@KEYCLOAK_CLIENT_ID@@'
};
