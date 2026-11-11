#!/bin/sh
set -eou pipefail

curl --insecure --fail --silent --show-error \
	--noproxy '*' \
	--resolve "$DOMAIN_NAME:$NGINX_PORT:127.0.0.1" \
	"https://$DOMAIN_NAME:$NGINX_PORT/" \
	--output /dev/null \
	--max-time 4
