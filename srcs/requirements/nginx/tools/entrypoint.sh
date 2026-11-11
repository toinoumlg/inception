#!/bin/sh
set -eou pipefail


KEY=/etc/ssl/cert.key
CERT=/etc/ssl/cert.crt

if [ ! -f "$KEY" ] || [ ! -f "$CERT" ]; then
sed "s|DOMAIN_PLACEHOLDER|$DOMAIN_NAME|g" "$REQ.template" > "$REQ"
openssl req -x509 -nodes -newkey rsa:2048 -days 365 -keyout "$KEY" -out "$CERT" -config "$REQ" -extensions req_ext
fi

cp "$CONF.template" "$CONF"	

sed -i "s|NGINX_PORT_PLACEHOLDER|$NGINX_PORT|g" "$CONF"
sed -i "s|DOMAIN_PLACEHOLDER|$DOMAIN_NAME|g" "$CONF"
sed -i "s|WP_PORT_PLACEHOLDER|$WP_PORT|g" "$CONF"

nginx -t

exec nginx -g "daemon off;"