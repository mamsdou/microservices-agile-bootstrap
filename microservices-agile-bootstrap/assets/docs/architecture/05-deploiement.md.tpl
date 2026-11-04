# 05 — Déploiement

## Environnements

| Environnement | Outil | Usage |
|---|---|---|
| Poste dev | Docker Compose | Stack complète, rechargement par `docker compose up -d --build` |
| Cluster | Kubernetes (kustomize) | Intégration / recette / production |

## Docker Compose

```bash
docker compose up -d --build   # démarre tout
docker compose ps              # état et santé
docker compose logs -f <svc>   # suivre un service
docker compose down -v         # arrêter et supprimer les volumes
```

Ordre de démarrage garanti par `depends_on … condition: service_healthy` : PostgreSQL et Config Server, puis Eureka, puis les services. Une image générique (`infra/docker/Dockerfile.java`) construit n'importe quel module avec l'argument `MODULE_PATH`.

## Kubernetes

Les manifests sont dans `k8s/` et assemblés par `kustomization.yaml` (namespace `@@PROJECT@@`).

1. Construire les images : `make images` (tag `@@PROJECT@@/<module>:0.1.0`).
2. Les rendre visibles du cluster : `minikube image load …`, `kind load docker-image …`, ou pousser vers un registre et adapter le préfixe d'image (`images:` dans `kustomization.yaml`).
3. Appliquer : `kubectl apply -k k8s`.
4. Vérifier : `kubectl -n @@PROJECT@@ get pods -w`.
5. Accéder : `kubectl -n @@PROJECT@@ port-forward svc/frontend 4200:80`, ou via l'Ingress (`@@PROJECT@@.local`, contrôleur Ingress requis).

Chaque Deployment déclare des sondes `liveness`/`readiness` sur Actuator, des requêtes/limites de ressources et lit sa configuration depuis la ConfigMap `app-config` et le Secret `app-secret`. Les pods Spring attendent le Config Server (initContainer) avant de démarrer.

## À durcir avant la production

- Remplacer le Secret de dev (valeurs en clair dans le dépôt) par un coffre (Sealed Secrets, External Secrets, Vault).
- Postgres, Kafka et Elasticsearch sont déployés en instance unique pour le dev : utiliser des services managés ou des opérateurs (CloudNativePG, Strimzi, ECK) en production.
- Ajouter des `NetworkPolicy`, des `PodDisruptionBudget`, plusieurs replicas et un `HorizontalPodAutoscaler`.
- Config Server : passer du backend `native` à un dépôt Git (ADR-0002).
