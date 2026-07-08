#!/bin/sh

sed -i "s|NGINX_PORT|$NGINX_PORT|g" $CONF
sed -i "s|DOMAIN|$DOMAIN_NAME|g" $CONF
sed -i "s|WP_PORT|$WP_PORT|g" $CONF

exec nginx -g "daemon off;"