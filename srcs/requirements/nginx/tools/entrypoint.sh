#!/bin/sh
set -eou pipefail


KEY=/etc/ssl/cert.key
CERT=/etc/ssl/cert.crt

if [ ! -f $KEY ] || [ ! -f $CERT ]; then
mkdir -p /etc/ssl

sed -i "s|DOMAIN|$DOMAIN_NAME|g" $REQ

openssl req -x509 -nodes -newkey rsa:2048 -days 365 -keyout $KEY -out $CERT -config $REQ -extensions req_ext
fi

sed -i "s|NGINX_PORT|$NGINX_PORT|g" $CONF
sed -i "s|DOMAIN|$DOMAIN_NAME|g" $CONF
sed -i "s|WP_PORT|$WP_PORT|g" $CONF

exec nginx -g "daemon off;"