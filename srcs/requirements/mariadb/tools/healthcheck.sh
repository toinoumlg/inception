#!/bin/sh
set -eou pipefail

exec mariadb-admin ping --protocol=tcp --host=127.0.0.1 \
	--port="$PORT" --user="$LOGIN" \
	--password="$(cat /run/secrets/db_user_pwd)" --silent
