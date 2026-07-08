#!/bin/sh

set -eou pipefail


if [ ! -f wp-config.php ]; then
	DB_PWD_FILE=/run/secrets/db_password
	ADMIN_PWD_FILE=/run/secrets/wp_admin
	LOGIN_PWD_FILE=/run/secrets/wp_login

	if [ ! -f $DB_PWD_FILE ] ||
		[ ! -f $ADMIN_PWD_FILE ] ||
		[ ! -f $LOGIN_PWD_FILE ]; then 
		echo "Secrets not provided"
		exit 1
	fi

	DB_PWD=$(cat $DB_PWD_FILE)
	ADMIN_PWD=$(cat $ADMIN_PWD_FILE)
	LOGIN_PWD=$(cat $LOGIN_PWD_FILE)

	wp config create --allow-root \
		--dbname=$DB_NAME \
		--dbuser=$LOGIN \
		--dbpass=$DB_PWD \
		--dbhost=$DB_HOST:$DB_PORT

	wp core install --url=$DOMAIN_NAME \
		--title=inception \
		--admin_user=$ADMIN_NAME \
		--admin_password=$ADMIN_PWD \
		--admin_email=$ADMIN_MAIL \
		--skip-email

	wp user create $LOGIN \
		$LOGIN_MAIL \
		--user_pass=$LOGIN_PWD \
		--role=editor
fi

exec php-fpm85 -F