FROM alpine:3.24

RUN apk update && apk add \
	mariadb mariadb-client

COPY --chmod=+x tools/entrypoint.sh /entrypoint.sh

COPY --chmod=+x tools/healthcheck.sh /healthcheck.sh

ENV CONF=/etc/my.cnf.d/mariadb-server.cnf

COPY conf/my.cnf /etc/my.cnf.d/mariadb-server.cnf.template

ENV DATADIR=/var/lib/mariadb

HEALTHCHECK --interval=10s --start-period=5s --timeout=3s \
	CMD ["/healthcheck.sh"]

ENTRYPOINT ["/entrypoint.sh"]