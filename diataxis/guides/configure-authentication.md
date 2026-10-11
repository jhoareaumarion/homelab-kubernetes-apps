# Configure authentication

_The "tutorial" of the how-to_

This tutorial explains how authentication works in this repository and how to wire a new app into it. It teaches the **Keycloak + oauth2-proxy** pattern used by `shared-authentication` and `actual-budget`.

> **When to read this**
> - You need single sign-on (SSO) for your app.
> - You want to restrict an app to authenticated users or specific roles.
> - You're adding an app to the `auth` category.

## How authentication works

The pattern separates three concerns:

1. **Identity provider** — **Keycloak** (`apps/keycloak/`) authenticates users and issues tokens. It is exposed at `auth.hoareau-marion.eu` (public) and `auth.private.hoareau-marion.eu` (admin UI).
2. **Gateway** — **oauth2-proxy** (`shared-authentication/`) sits in front of each protected app. It validates the Keycloak token and, if valid, proxies the request to the app.
3. **App** — the backend service (e.g. `actual-budget`) receives already-authenticated requests.

```
User ──► auth.hoareau-marion.eu (Keycloak) ──► login
User ──► <app>.hoareau-marion.eu ──► oauth2-proxy (validates token) ──► <app>
```

## The shared-authentication layer

`apps/shared-authentication/` hosts one oauth2-proxy deployment per protected app, each configured to talk to Keycloak:

```
shared-authentication/
├── envoy-config.yaml   # Cilium ext_authz rules wiring oauth2-proxy into the data plane
├── sonarr/
│   ├── deployment.yaml # oauth2-proxy-sonarr (port 4180)
│   ├── cm.yaml         # oauth2-proxy.cfg (Keycloak client config)
│   ├── service.yaml    # auth-sonarr Service
│   ├── sonarr-secrets.secrets.yaml
│   ├── sonarr-secrets.sealed.yaml
│   └── reference-grant.yaml
├── radarr/
├── prowlarr/
└── moonlight/
```

Each app subdirectory contains:

- **`deployment.yaml`** — runs `oauth2-proxy` on port `4180`, reading its config from a mounted ConfigMap and its secrets from a sealed secret.
- **`cm.yaml`** — the `oauth2-proxy.cfg` file. Key settings:
  - `provider = "keycloak-oidc"`
  - `oidc_issuer_url = "https://auth.hoareau-marion.eu/realms/milkyway"`
  - `client_id = "<app-client-id>"`
  - `allowed_roles = [ "<role>:<scope>" ]` — restricts access to specific roles.
  - `upstreams = [ "http://<app>-webui.<app>.svc.cluster.local:<port>/" ]` — the backend.
- **`service.yaml`** — the `auth-<app>` Service (port `80` → `4180`).
- **`<app>-secrets.secrets.yaml`** — the oauth2-proxy `client-secret` and `cookie-secret`.
- **`<app>-secrets.sealed.yaml`** — the sealed version.
- **`reference-grant.yaml`** — authorizes the route to reach the `auth-<app>` Service across namespaces.

### Example: oauth2-proxy config (sonarr)

```yaml
data:
  oauth2-proxy.cfg: |
    provider = "keycloak-oidc"
    oidc_issuer_url = "https://auth.hoareau-marion.eu/realms/milkyway"
    client_id = "sonarr"
    http_address = "0.0.0.0:4180"
    email_domains = [ "*" ]
    allowed_roles = [ "sonarr:sonarr-user" ]
    skip_auth_regex = [ "^/api/.*", "^/[0-9]+/api.*" ]
    whitelist_domains = [ ".hoareau-marion.eu" ]
    upstreams = [ "http://sonarr-webui.sonarr.svc.cluster.local:8989/" ]
    pass_host_header = true
    reverse_proxy = true
    skip_provider_button = true
```

## Wiring a new app into authentication

To protect a new app with the same pattern:

1. **Create an oauth2-proxy subdirectory** `apps/shared-authentication/<app>/` with the manifests above.
2. **Set the Keycloak client** (`client_id`, `allowed_roles`) in the oauth2-proxy ConfigMap.
3. **Point `upstreams`** at your app's Service.
4. **Add a ReferenceGrant** so the route can reach `auth-<app>`.
5. **Expose the app** via a route that oauth2-proxy terminates auth for.

> **Note**: `actual-budget` currently does **not** use this oauth2-proxy layer — it is exposed directly. The authentication pattern is demonstrated by `shared-authentication` and `keycloak`.

## Keycloak specifics

`apps/keycloak/` runs Keycloak with a Postgres database:

- **Realm**: `milkyway`
- **Public route**: `auth.hoareau-marion.eu` → `/realms/milkyway` and `/resources`
- **Admin route**: `auth.private.hoareau-marion.eu` → full admin UI
- **ConfigMap** sets `KC_PROXY_HEADERS: xforwarded`, `KC_HOSTNAME`, and `KC_HTTP_ENABLED: true`.
- **Database**: nested `db/` directory (Postgres Deployment, Service, PVC, ConfigMap).
- **Bootstrap admin**: `keycloak-administrator` / (sealed secret).

## Reference implementations

- **Keycloak + Postgres**: `apps/keycloak/` — the full auth provider with a database.
- **oauth2-proxy integration**: `apps/shared-authentication/` — the per-app proxy layer.
- **Direct exposure (no auth)**: `apps/actual-budget/` — a simple app exposed without the auth layer.

See [reference/actual-budget.md](../reference/actual-budget.md) for the plain app and [reference/conventions.md](../reference/conventions.md) for the routing and secret conventions.
