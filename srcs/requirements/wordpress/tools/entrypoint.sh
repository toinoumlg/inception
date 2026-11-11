#!/bin/sh
set -eou pipefail

sed "s|WP_PORT_PLACEHOLDER|$WP_PORT|g" "$CONF.template" > "$CONF"

DB_PWD_FILE=/run/secrets/db_user_pwd
ADMIN_PWD_FILE=/run/secrets/wp_admin_pwd
LOGIN_PWD_FILE=/run/secrets/wp_login_pwd

if [ ! -f "$DB_PWD_FILE" ] ||
	[ ! -f "$ADMIN_PWD_FILE" ] ||
	[ ! -f "$LOGIN_PWD_FILE" ]; then 
	echo "Secrets not provided"
	exit 1
fi

DB_PWD=$(cat $DB_PWD_FILE)
ADMIN_PWD=$(cat $ADMIN_PWD_FILE)
LOGIN_PWD=$(cat $LOGIN_PWD_FILE)

if [ ! -f wp-config.php ]; then
	wp config create --dbname="$DB_NAME" \
		--dbuser="$LOGIN" --dbpass="$DB_PWD" \
		--dbhost="$DB_HOST:$DB_PORT"
fi

if ! wp core is-installed; then
	wp core install --url="https://$DOMAIN_NAME" \
		--title=inception --admin_user="$ADMIN_NAME" \
		--admin_password="$ADMIN_PWD" --admin_email="$ADMIN_MAIL" \
		--skip-email
fi

if ! wp user get "$LOGIN" >/dev/null 2>&1; then
	wp user create "$LOGIN" "$LOGIN_MAIL" \
		--user_pass="$LOGIN_PWD" --role=editor
		
fi

php-fpm85 -t

exec php-fpm85 -F
