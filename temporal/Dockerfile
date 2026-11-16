# Temporal server for Railway. The stock server image can't create or migrate
# its database, so the SQL schema tool, the schema files and the `temporal` CLI
# come from the matching admin-tools image. Bump both pins together.
FROM temporalio/admin-tools:1.32.2@sha256:4a95866efba29d7e17ab012df5232795e8b0ad0f7d5f9d1ec4df321f7792a754 AS tools

FROM temporalio/server:1.32.2@sha256:7bf69188a6232fea14869b9cef3d94aa82a1601d99517f7e86c71f22da4e0670
COPY --from=tools /usr/local/bin/temporal-sql-tool /usr/local/bin/temporal-sql-tool
COPY --from=tools /usr/local/bin/temporal /usr/local/bin/temporal
COPY --from=tools /etc/temporal/schema/postgresql/v12 /etc/temporal/schema/postgresql/v12
COPY dynamicconfig.yaml /etc/temporal/config/dynamicconfig/docker.yaml
COPY start.sh /etc/temporal/railway-start.sh

# Listen on all addresses (Railway's private network is IPv6); the server's own
# services find each other on loopback. The frontend is reachable only on the
# private network, so it runs without an authorizer. TEMPORAL_ADDRESS lets the
# bundled `temporal` CLI talk to this server from a shell in the container.
ENV DB=postgres12 \
    DB_PORT=5432 \
    BIND_ON_IP=:: \
    TEMPORAL_BROADCAST_ADDRESS=127.0.0.1 \
    TEMPORAL_ALLOW_NO_AUTH=true \
    TEMPORAL_ADDRESS=127.0.0.1:7233 \
    NUM_HISTORY_SHARDS=4 \
    LOG_LEVEL=warn

EXPOSE 7233 7243
CMD ["/etc/temporal/railway-start.sh"]
