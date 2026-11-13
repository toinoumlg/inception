FROM alpine:3.23

RUN apk update && apk add \
	nginx \
	openssl \
	curl

ENV CONF=/etc/nginx/http.d/default.conf

ENV REQ=/etc/ssl/req.conf

COPY conf/default.conf /etc/nginx/http.d/default.conf.template

COPY conf/req.conf /etc/ssl/req.conf.template

COPY --chmod=+x tools/entrypoint.sh /entrypoint.sh

COPY --chmod=+x tools/healthcheck.sh /healthcheck.sh

HEALTHCHECK --interval=10s --start-period=15s --timeout=5s \
	CMD ["/healthcheck.sh"]

ENTRYPOINT ["/entrypoint.sh"]
