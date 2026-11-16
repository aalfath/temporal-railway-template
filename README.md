# Temporal on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/temporal-1?utm_medium=integration&utm_source=button&utm_campaign=temporal)

Railway template for [Temporal](https://temporal.io), the open-source durable execution platform: the Temporal server, its Web UI behind a password, and Railway Postgres. Every app service builds from this repo, so a merge to `main` here shows up as an "update available" notice in the projects of everyone who deployed the template. Each deployer chooses when to apply it.

## What it deploys

| Service | Source | Notes |
|---|---|---|
| **Temporal** | `temporal/` in this repo: `temporalio/server:1.32.2`, plus `temporal-sql-tool`, the Postgres schema files and the `temporal` CLI from `temporalio/admin-tools:1.32.2`, both pinned by digest | Creates and migrates its `temporal` and `temporal_visibility` databases on every start, then registers the `default` namespace (72h retention). gRPC frontend on port 7233, private network only. |
| **Temporal UI** | `ui/` in this repo: `temporalio/ui:2.58.1` plus Caddy 2.11.9 (basic auth), both pinned by digest | Public domain. Login `admin` with a password generated at deploy time. |
| **Postgres** | Railway Postgres | Workflow history and visibility. No Elasticsearch needed: Postgres visibility supports custom search attributes. |

## Connecting workers

Run your workers (any Temporal SDK) as services in the same Railway project and point them at the private address:

```
TEMPORAL_ADDRESS=${{Temporal.RAILWAY_PRIVATE_DOMAIN}}:7233
TEMPORAL_NAMESPACE=default
```

The frontend runs without TLS or an authorizer, which is safe only because it is not exposed outside the project. Don't add a public TCP proxy to port 7233 unless you first configure mTLS (see [Temporal security](https://docs.temporal.io/self-hosted-guide/security)).

The `temporal` CLI is included in the Temporal service. From a shell in that service (`railway ssh`), for example:

```
temporal operator namespace create --namespace orders --retention 168h
temporal workflow list
```

## Variables

Set by the template. You don't need to enter anything at deploy time.

| Service | Variable | Value |
|---|---|---|
| Temporal | `POSTGRES_SEEDS`, `POSTGRES_USER`, `POSTGRES_PWD`, `DB_PORT` | references to Postgres |
| Temporal | `PORT` | `7243` (Temporal's HTTP API, used for the health check `/api/v1/namespaces/default`) |
| Temporal UI | `TEMPORAL_ADDRESS` | `${{Temporal.RAILWAY_PRIVATE_DOMAIN}}:7233` |
| Temporal UI | `UI_USERNAME` | `admin` |
| Temporal UI | `UI_PASSWORD` | generated secret: read it in the service's Variables tab |
| Temporal UI | `PORT` | `8080` (Caddy) |

Optional, add them yourself: `DEFAULT_NAMESPACE` and `NAMESPACE_RETENTION` (for example `168h`) on Temporal change the namespace created at first start; `NUM_HISTORY_SHARDS` (default 4) can only be chosen before the first start. Any `TEMPORAL_*` setting of the [UI server](https://github.com/temporalio/ui-server) (OIDC login, read-only mode, banner) works on Temporal UI.

## Updates

New Temporal releases land here as a pull request that bumps the pinned tags and digests and adds a `CHANGELOG.md` entry. Each one is tested on a scratch Railway project before it's merged. Read the changelog before you apply an update in your project. The server migrates its schema on start. Temporal supports upgrading one minor version at a time (1.31 → 1.32), so apply updates in order.

Upstream: [Temporal server](https://github.com/temporalio/temporal) (MIT), [Temporal UI](https://github.com/temporalio/ui) (MIT), [self-hosting guide](https://docs.temporal.io/self-hosted-guide), [Caddy](https://caddyserver.com) (Apache-2.0).
