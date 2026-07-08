#!/bin/sh
set -eou pipefail

sed -i "s|port=.*|port=$PORT|g" $CONF
sed -i "s|socket=.*|socket=$DATADIR/$DB_NAME/$DB_NAME.sock|g" $CONF

# if first time running, datadir/mysql/ doesnt exist
if [ ! -d "$DATADIR/mysql" ]; then
	ROOT_FILE=/run/secrets/db_root_password
	USER_FILE=/run/secrets/db_password

	if [ ! -f "$ROOT_FILE" ] || [ ! -f "$USER_FILE" ]; then
		echo "Secrets not provided"
		exit 1
	fi

	# creates required folders and set permissions
	mkdir -p "$DATADIR"
	chown -R mysql:mysql "$DATADIR"

	# recover passwords from secrets
	DB_ROOT_PWD=$(cat "$ROOT_FILE")
	DB_PWD=$(cat "$USER_FILE")

	mariadb-install-db --skip-test-db

	# creates initialization sql file
	cat <<EOF | mariadbd --bootstrap --skip-grant-tables=0
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PWD}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${LOGIN}'@'%' IDENTIFIED BY '${DB_PWD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${LOGIN}'@'%';
FLUSH PRIVILEGES;
EOF

fi

# exec mariadbd, becomes PID 1 so our container status is related to this process
exec mariadbd --skip-networking=0