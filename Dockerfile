FROM mysql:8.0

ENV MIGRATE_VERSION=v4.15.2

RUN apt-get update \
  && apt-get install -y --no-install-recommends wget ca-certificates default-mysql-client \
  && wget -O /usr/local/bin/migrate https://github.com/golang-migrate/migrate/releases/download/${MIGRATE_VERSION}/migrate.linux-amd64 \
  && chmod +x /usr/local/bin/migrate \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /migrations

COPY migrations /migrations
COPY entrypoint.sh /usr/local/bin/migrate-entrypoint.sh
RUN chmod +x /usr/local/bin/migrate-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/migrate-entrypoint.sh"]

EXPOSE 3306

CMD ["up"]
