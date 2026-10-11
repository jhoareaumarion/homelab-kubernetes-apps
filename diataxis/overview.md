# Overview

_The "introduction" of the tutorial_

This repository is a collection of Kubernetes applications for a homelab, managed end-to-end with **ArgoCD** and deployed through an **ingress-nginx** gateway. This overview tells you how the pieces fit together and how to get oriented; for step-by-step instructions see the guides, for concrete copy-paste manifests see the how-to guides, and for exact values see the reference.

## What this repo contains

- **`apps/`** — one directory per application. Each app ships as an ArgoCD `Application` manifest plus its Kubernetes manifests (Deployment, Service, Route, ConfigMap, Secret, etc.).
- **`apps/cluster-gateway/`** — the shared networking infrastructure:
  - `ingress-gateway/` — the public ingress controller and its sections.
  - `external-dns/` — dynamically provisions DNS records from the routes.
- **`apps/infrastructure/`** — cluster infrastructure (CNI networking, ArgoCD itself, NFS, etc.).
- **`shared-authentication/`** — a shared OAuth2-proxy + Keycloak authentication layer that individual apps can plug into.

## The deployment flow

```
Internet
   │
   ▼
Public HTTPS terminators (cert-manager / letsencrypt)
   │
   ▼
ingress-nginx Ingress (cluster-gateway/ingress-gateway)
   │   routed by HTTPRoute + sections (web-https, auth-https, ...)
   ▼
Per-app Services → Deployments (apps/<app-name>/)
   │
   ▼
ArgoCD (apps/argocd or infrastructure) keeps cluster state in sync with this repo
```

1. **ArgoCD** watches this Git repository (`app-of-apps.yaml` is the root Application that fans out to every app Application).
2. Each **Application** points at a subdirectory under `apps/` and applies its manifests into a dedicated namespace.
3. **ingress-nginx** exposes apps over HTTPS via `HTTPRoute` resources attached to named **sections**.
4. **ExternalDNS** reads those routes and creates the public DNS records (`<app>.hoareau-marion.eu`).

## Key concepts

| Concept | Where to learn it |
| --- | --- |
| How to add a new app | [guides/create-a-new-app.md](guides/create-a-new-app.md) |
| The manifest-by-manifest anatomy of an app | [reference/actual-budget.md](reference/actual-budget.md) |
| Repository-wide conventions (secrets, labels, routing) | [reference/conventions.md](reference/conventions.md) |

## Domain-specific guides

- **Authentication** — [guides/configure-authentication.md](guides/configure-authentication.md) explains the Keycloak + oauth2-proxy pattern used by apps like `shared-authentication` and `actual-budget`.

## Where to start

- **New to the repo?** Read this overview, then follow [guides/create-a-new-app.md](guides/create-a-new-app.md).
- **Need exact values?** Consult the reference pages.
- **Stuck on a pattern?** See the corresponding tutorial or the reference glossary.
