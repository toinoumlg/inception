FROM alpine:3.24

RUN apk update && apk add \
	nginx \
	openssl

ENV CONF=/etc/nginx/http.d/default.conf
ENV REQ=/etc/ssl/req.conf

COPY conf/amalangu.42.fr $CONF
COPY conf/req.conf $REQ

COPY --chmod=+x tools/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]