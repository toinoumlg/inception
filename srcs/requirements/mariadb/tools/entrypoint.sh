#!/bin/sh
set -eou pipefail

sql_escape() {
	printf '%s' "$1" | sed "s/'/''/g"
}

cp "$CONF.template" "$CONF"
sed -i "s|PORT_PLACEHOLDER|$PORT|g" "$CONF"
sed -i "s|SOCKET_PLACEHOLDER|$DATADIR/$DB_NAME/$DB_NAME.sock|g" "$CONF"

ROOT_FILE=/run/secrets/db_root_pwd
USER_FILE=/run/secrets/db_user_pwd

if [ ! -f "$ROOT_FILE" ] || [ ! -f "$USER_FILE" ]; then
	echo "Secrets not provided"
	exit 1
fi

# recover passwords from secrets

ROOT_PWD=$(cat "$ROOT_FILE")
USER_PWD=$(cat "$USER_FILE")

ROOT_SQL=$(sql_escape "$ROOT_PWD")
USER_SQL=$(sql_escape "$USER_PWD")

case "$DB_NAME" in
	''|*[!a-zA-Z0-9_]*) echo "invalid  database name" >&2; exit 1;;
esac

case "$LOGIN" in
	''|*[!a-zA-Z0-9_]*) echo "invalid  login name" >&2; exit 1;;
esac

# if first time running, datadir/mysql/ doesnt exist
if [ ! -d "$DATADIR/mysql" ]; then
	# creates required folders and set permissions
	mkdir -p "$DATADIR/$DB_NAME"
	chown -R mysql:mysql "$DATADIR"
	# install db without test entries
	mariadb-install-db --skip-test-db
fi

if [ ! -f "$DATADIR/.bootstrap_complete" ]; then
	# creates initialization sql file user and root
	cat <<EOF | mariadbd --bootstrap --skip-grant-tables=0
SET SESSION sql_mode = 'NO_BACKSLASH_ESCAPES';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_SQL}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${LOGIN}'@'%' IDENTIFIED BY '${USER_SQL}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${LOGIN}'@'%';
FLUSH PRIVILEGES;
EOF

touch "$DATADIR/.bootstrap_complete"
fi

exec mariadbd --skip-networking=0