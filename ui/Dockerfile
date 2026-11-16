# Temporal Web UI for Railway. The UI has no login of its own (only optional
# OIDC), so Caddy sits in front of it with HTTP basic auth. Caddy's static
# binary is copied from the official image. Bump the UI pin on its own; Caddy
# only when needed.
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

FROM temporalio/ui:2.58.1@sha256:ac3c13eddb4547d830991bb5eee93a5d97140134522b7297fdb2be1fe25ef925
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /home/ui-server/Caddyfile
COPY start.sh /home/ui-server/railway-start.sh

# The UI server listens on 8233 (reached by Caddy on loopback); only Caddy, on
# Railway's PORT, gets the public domain.
ENV TEMPORAL_UI_PORT=8233 \
    UI_USERNAME=admin \
    XDG_CONFIG_HOME=/tmp \
    XDG_DATA_HOME=/tmp

EXPOSE 8080
ENTRYPOINT ["/home/ui-server/railway-start.sh"]
