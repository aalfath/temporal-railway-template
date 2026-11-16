#!/bin/sh
# Create and migrate Temporal's two Postgres databases, start the server, and
# register the default namespace once the frontend answers.
set -eu
: "${POSTGRES_SEEDS:?set POSTGRES_SEEDS to the Postgres host}"
: "${POSTGRES_USER:?set POSTGRES_USER}"
: "${POSTGRES_PWD:?set POSTGRES_PWD}"
NAMESPACE="${DEFAULT_NAMESPACE:-default}"
RETENTION="${NAMESPACE_RETENTION:-72h}"
HTTP_PORT="${FRONTEND_HTTP_PORT:-7243}"
SCHEMA=/etc/temporal/schema/postgresql/v12

sqltool() {
  db="$1"; shift
  temporal-sql-tool --plugin postgres12 --endpoint "$POSTGRES_SEEDS" --port "${DB_PORT:-5432}" \
    --user "$POSTGRES_USER" --password "$POSTGRES_PWD" --database "$db" "$@"
}

migrate() {
  for pair in "${DBNAME:-temporal}:temporal" "${VISIBILITY_DBNAME:-temporal_visibility}:visibility"; do
    db="${pair%%:*}"; dir="${pair#*:}"
    sqltool "$db" create-database >/dev/null 2>&1 || true   # fine if it already exists
    sqltool "$db" setup-schema -v 0.0 >/dev/null 2>&1 || true # fine if already set up
    sqltool "$db" update-schema -d "$SCHEMA/$dir/versioned" || return 1
  done
}

n=0
until migrate; do
  n=$((n + 1))
  [ "$n" -ge 40 ] && { echo "Temporal schema migration failed" >&2; exit 1; }
  echo "Waiting for Postgres ($n)..."
  sleep 3
done
echo "Temporal schema is up to date."

# Register the namespace through the frontend's HTTP API once it is up.
(
  api="http://127.0.0.1:${HTTP_PORT}/api/v1/namespaces"
  secs=$(echo "$RETENTION" | sed 's/h$//'); secs=$((secs * 3600))
  i=0
  while [ "$i" -lt 100 ]; do
    i=$((i + 1)); sleep 3
    if wget -q -O /dev/null "$api/$NAMESPACE" 2>/dev/null; then exit 0; fi
    if wget -q -O /dev/null --header 'Content-Type: application/json' \
        --post-data "{\"namespace\":\"$NAMESPACE\",\"workflowExecutionRetentionPeriod\":\"${secs}s\"}" "$api" 2>/dev/null; then
      echo "Created Temporal namespace '$NAMESPACE' (retention $RETENTION)."
      exit 0
    fi
  done
  echo "Could not create Temporal namespace '$NAMESPACE'" >&2
) &

exec temporal-server start
