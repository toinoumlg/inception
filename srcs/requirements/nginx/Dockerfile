FROM alpine:3.24

RUN apk update && apk add \
	nginx \
	openssl

ENV CONF=/etc/nginx/http.d/default.conf

COPY conf/amalangu.42.fr $CONF

RUN openssl req -x509 -nodes -days 5 -newkey rsa:2048 \
	-keyout /etc/ssl/.key \
	-out /etc/ssl/.crt \
	-subj "/C=FR/L=Lyon/O=42/CN=amalangu.42.fr"

COPY --chmod=+x tools/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]