# Changelog

## 1.32.2 (2026-11-16)

First release of the template.

- Temporal server 1.32.2 (`temporalio/server`) with `temporal-sql-tool`, Postgres v12 schema files and the `temporal` CLI from `temporalio/admin-tools:1.32.2`.
- Temporal UI 2.58.1 (`temporalio/ui`) behind Caddy 2.11.9 basic auth.
- Railway Postgres for history and visibility; schema created and migrated on every start; `default` namespace registered with 72h retention.
