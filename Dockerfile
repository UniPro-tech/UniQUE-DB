# Multi-stage: build migrate binary in Debian, then copy into MySQL base image
FROM debian:bullseye-slim AS builder

ENV MIGRATE_VERSION v4.15.2

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates wget \
  && rm -rf /var/lib/apt/lists/*

RUN wget -O /usr/local/bin/migrate https://github.com/golang-migrate/migrate/releases/download/${MIGRATE_VERSION}/migrate.linux-amd64 \
  && chmod +x /usr/local/bin/migrate

FROM mysql:8.0

COPY --from=builder /usr/local/bin/migrate /usr/local/bin/migrate

ENV MIGRATIONS_DIR=/migrations

RUN mkdir -p ${MIGRATIONS_DIR}

COPY migrations ${MIGRATIONS_DIR}
COPY entrypoint.sh /usr/local/bin/migrate-entrypoint.sh
RUN chmod +x /usr/local/bin/migrate-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/migrate-entrypoint.sh"]
CMD ["up"]
