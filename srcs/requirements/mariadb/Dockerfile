FROM alpine:3.24

RUN apk update && apk add \
	mariadb mariadb-client

COPY --chmod=+x tools/entrypoint.sh /entrypoint.sh

ENV CONF=/etc/my.cnf.d/mariadb-server.cnf

COPY conf/my.cnf $CONF

ENV DATADIR=/var/lib/mariadb

ENTRYPOINT ["/entrypoint.sh"]