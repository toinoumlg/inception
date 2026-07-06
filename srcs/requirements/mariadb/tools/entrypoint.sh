#!/bin/sh

set -eou pipefail

ROOT_FILE=/run/secrets/db_root_password
USER_FILE=/run/secrets/db_password

if [ ! -f "$ROOT_FILE" ] || [ ! -f "$USER_FILE" ]; then
	echo "Secrets not provided"
	exit 1
fi

DATADIR=/var/lib/mysql

# creates required folders and set permissions
mkdir -p /run/mysqld "$DATADIR"
chown -R mysql:mysql /run/mysqld "$DATADIR"

# recover passwords from secrets
DB_ROOT_PASSWORD=$(cat "$ROOT_FILE")
DB_PASSWORD=$(cat "$USER_FILE")

# if first time running, datadir/mysql/ doesnt exist
if [ ! -d "$DATADIR/mysql" ]; then

	mariadb-install-db --skip-test-db

	# creates initialization sql file
	cat <<EOF | mariadbd --bootstrap --skip-grant-tables=0
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_NAME}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_NAME}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

fi

# exec mariadbd, becomes PID 1 so our container status is related to this process
exec mariadbd --port="$MYSQL_PORT" --skip-networking=0