name: CI

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'
          cache: maven
      - name: Build et tests unitaires
        run: mvn -B verify

  frontend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm install --no-audit --no-fund
      - run: npx ng build --configuration production

  infra:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Valider docker-compose
        run: docker compose config -q
      - name: Valider les manifests Kubernetes
        run: kubectl kustomize k8s > /dev/null
