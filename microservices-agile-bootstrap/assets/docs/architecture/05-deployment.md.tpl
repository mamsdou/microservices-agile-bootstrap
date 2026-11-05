# 05 — Deployment

## Environments

| Environment | Tool | Use |
|---|---|---|
| Dev machine | Docker Compose | Full stack, reload with `docker compose up -d --build` |
| Cluster | Kubernetes (kustomize) | Integration / staging / production |

## Docker Compose

```bash
docker compose up -d --build   # start everything
docker compose ps              # status and health
docker compose logs -f <svc>   # follow a service
docker compose down -v         # stop and remove volumes
```

Startup order is guaranteed by `depends_on … condition: service_healthy`: PostgreSQL and Config Server, then Eureka, then the services. A generic image (`infra/docker/Dockerfile.java`) builds any module with the `MODULE_PATH` argument.

## Kubernetes

Manifests are in `k8s/` and assembled by `kustomization.yaml` (namespace `@@PROJECT@@`).

1. Build the images: `make images` (tag `@@PROJECT@@/<module>:0.1.0`).
2. Make them visible to the cluster: `minikube image load …`, `kind load docker-image …`, or push to a registry and adapt the image prefix (`images:` in `kustomization.yaml`).
3. Apply: `kubectl apply -k k8s`.
4. Check: `kubectl -n @@PROJECT@@ get pods -w`.
5. Access: `kubectl -n @@PROJECT@@ port-forward svc/frontend 4200:80`, or through the Ingress (`@@PROJECT@@.local`, Ingress controller required).

Each Deployment declares `liveness`/`readiness` probes on Actuator and resource requests/limits, and reads its configuration from the `app-config` ConfigMap and `app-secret` Secret. Spring pods wait for the Config Server (initContainer) before starting.

## To harden before production

- Replace the dev Secret (plain values in the repository) with a vault (Sealed Secrets, External Secrets, Vault).
- Postgres, Kafka and Elasticsearch are deployed as single instances for dev: use managed services or operators (CloudNativePG, Strimzi, ECK) in production.
- Add `NetworkPolicy`, `PodDisruptionBudget`, several replicas and a `HorizontalPodAutoscaler`.
- Config Server: move from the `native` backend to a Git repository (ADR-0002).
