# Multi-stage: build migrate binary in Debian, then copy into MySQL base image
FROM debian:bullseye-slim AS builder

ENV version=v4.15.2
ENV os=linux
ENV arch=amd64

RUN apt-get update && apt-get install -y curl ca-certificates

RUN curl -L https://github.com/golang-migrate/migrate/releases/download/$version/migrate.$os-$arch.tar.gz | tar xvz

RUN mv migrate /usr/local/bin/migrate

FROM mysql:8.0

COPY --from=builder /usr/local/bin/migrate /usr/local/bin/migrate

ENV MIGRATIONS_DIR=/migrations

RUN mkdir -p ${MIGRATIONS_DIR}

COPY migrations ${MIGRATIONS_DIR}
COPY entrypoint.sh /usr/local/bin/migrate-entrypoint.sh
RUN chmod +x /usr/local/bin/migrate-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/migrate-entrypoint.sh"]
CMD ["up"]
