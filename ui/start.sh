#!/bin/bash
# Start the Temporal UI server on loopback and Caddy (basic auth) on $PORT.
# If either process exits, the container exits so Railway restarts it.
set -eu -o pipefail
: "${TEMPORAL_ADDRESS:?set TEMPORAL_ADDRESS to the Temporal frontend, host:7233}"
: "${UI_PASSWORD:?set UI_PASSWORD (the UI login password)}"
export PORT="${PORT:-8080}"
export UI_USERNAME="${UI_USERNAME:-admin}"

# Accept the UI's own requests from the public domain.
if [ -z "${TEMPORAL_CORS_ORIGINS:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export TEMPORAL_CORS_ORIGINS="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

UI_PASSWORD_HASH="$(caddy hash-password --plaintext "$UI_PASSWORD")"
export UI_PASSWORD_HASH

cd /home/ui-server
./ui-server --env docker start &
caddy run --config /home/ui-server/Caddyfile --adapter caddyfile &
wait -n
echo "A process exited; stopping the container." >&2
exit 1
