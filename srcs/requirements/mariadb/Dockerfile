FROM alpine:3.24

RUN apk update && apk add mariadb 

# RUN apk add mariadb-client

COPY --chmod=+x tools/entrypoint.sh /entrypoint.sh

COPY conf/my.cnf /etc/my.cnf.d/mariadb-server.cnf

ENTRYPOINT ["/entrypoint.sh"]
# ENTRYPOINT tail -f /dev/null