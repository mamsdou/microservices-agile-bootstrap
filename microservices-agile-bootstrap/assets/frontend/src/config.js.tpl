// Configuration d'execution du frontend. Surchargeable sans reconstruire l'image
// (volume Docker ou ConfigMap Kubernetes monte sur /usr/share/nginx/html/config.js).
window.APP_CONFIG = {
  keycloakUrl: 'http://localhost:8180',
  realm: '@@KEYCLOAK_REALM@@',
  clientId: '@@KEYCLOAK_CLIENT_ID@@'
};
