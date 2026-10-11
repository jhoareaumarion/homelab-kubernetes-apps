# Practice

_The "exercises" of the tutorial_

This page provides hands-on exercises to reinforce what you've learned. Work through them in order: they build on the tutorial and reference material.

> **Note**: These exercises assume you have access to the cluster and can edit this repository. Some steps (sealing secrets, modifying Keycloak realms) require cluster access and care.

## Exercise 1 — Duplicate actual-budget

Create a new app called `my-budget` by copying `apps/actual-budget/`:

1. `cp -r apps/actual-budget apps/my-budget`
2. Rename `actual-budget` → `my-budget` in every manifest.
3. Change the hostname to `my-budget.hoareau-marion.eu` (route + certificate).
4. Update the image to something you control (or keep it as a placeholder).
5. Create the ArgoCD Application `apps/my-budget.yaml`.
6. `kubectl apply -f apps/my-budget/` and confirm the pod runs.

## Exercise 2 — Add a database

Take the keycloak database pattern and add a Postgres sidecar-style DB to a simple app:

1. Study `apps/keycloak/db/` (deployment, service, pvc, cm).
2. Replicate the structure for your app.
3. Have your Deployment pull `POSTGRES_PASSWORD` from the shared secret.

## Exercise 3 — Add authentication

Wire a new app into the oauth2-proxy layer:

1. Create `apps/shared-authentication/<app>/` with the oauth2-proxy manifests.
2. Configure the Keycloak client in the oauth2-proxy ConfigMap.
3. Add the ReferenceGrant and expose the app.

## Exercise 4 — Add a new ingress section

1. Add a new `sectionName` to the ingress gateway.
2. Add a route to that section.
3. Verify ExternalDNS picks up the new route.

## Where to get help

- **What to change and why**: [reference/actual-budget.md](../reference/actual-budget.md)
- **Conventions to follow**: [reference/conventions.md](../reference/conventions.md)
- **Full walkthrough**: [guides/create-a-new-app.md](../guides/create-a-new-app.md)
