# Documentation index

_Documentation map for the homelab-kubernetes-apps repository_

This documentation follows the [Diataxis](https://diataxis.fr) framework, covering four types of content:

- **Tutorial** — *how-to* guides that walk you through tasks.
- **Reference** — precise descriptions of the manifests and conventions.
- **Overview** — a high-level introduction to orient you.
- **Practice** — exercises to reinforce your learning.

## Getting started

- **[Overview](overview.md)** — how the repository fits together and the deployment flow.
- **[Guides](guides/)** — step-by-step instructions.
- **[Reference](reference/)** — exact manifest values and conventions.
- **[Practice](practice/)** — hands-on exercises.

## Guides (how-to)

| Guide | What it teaches |
| --- | --- |
| [Create a new app](guides/create-a-new-app.md) | Add a new application to the repository, following the actual-budget pattern. |
| [Configure authentication](guides/configure-authentication.md) | Wire apps into the Keycloak + oauth2-proxy authentication layer. |

## Reference (glossary)

| Reference | What it covers |
| --- | --- |
| [actual-budget](reference/actual-budget.md) | File-by-file anatomy of the actual-budget app. |
| [Conventions](reference/conventions.md) | Repository-wide patterns: layout, labels, secrets, routing, databases. |

## Practice (exercises)

- [Exercises](practice/index.md) — hands-on tasks to solidify your understanding.
