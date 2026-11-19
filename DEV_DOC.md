# Developer Documentation

This document explains how to set up the **Inception** development environment from scratch, understand the repository architecture, build and debug the containers, and manage persistent storage.

---

## Environment Setup from Scratch

Starting from a fresh Linux installation inside a virtual machine.

### 1. Virtual Machine Setup (QEMU/KVM or VirtualBox)

Download the [**Debian netinst ISO**](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.7.0-amd64-netinst.iso) and create a VM from it. Once logged in, install the required base utilities:

```sh
sudo apt update && sudo apt install -y make git curl
```

### 2. Configure Local Hostname Resolution

To make `<login>.42.fr` resolve to `127.0.0.1` (`localhost`), add an entry to `/etc/hosts`:

```sh
sudo nano /etc/hosts
```

Add a line matching your `DOMAIN_NAME`, for example:

```text
127.0.0.1 amalangu.42.fr
```

<div align="center">

![hosts file updated](docs/imgs/hosts.png)
*`/etc/hosts` updated with the project domain*

</div>

### 3. Install Docker Engine on Debian

Follow the official [**Docker Engine for Debian**](https://docs.docker.com/engine/install/debian/) installation steps:

```sh
# Remove unofficial or conflicting packages if installed
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)
```

```sh
# Add Docker's official GPG key
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

```sh
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Apply the [Linux post-install step](https://docs.docker.com/engine/install/linux-postinstall/) so your user can run Docker commands without `sudo`, then reboot to apply group membership:

```sh
sudo usermod -aG docker $USER && sudo reboot
```

### 4. Clone the Repository

```sh
git clone https://github.com/toinoumlg/inception.git
cd inception
```

### 5. Configure Environment Variables and Secrets

Create the `.env` file and the `secrets/` directory from the provided templates (both are listed in [`.gitignore`](.gitignore) so credentials are never committed):

```sh
cp srcs/.env.example srcs/.env
cp -r secrets.tofill secrets
```

#### `srcs/.env` Reference

Edit `srcs/.env` and replace all `CHANGE_ME` values:

| Variable | Default / Example | Description & Constraints |
|---|---|---|
| `COMPOSE_PROJECT_NAME` | `inception` | Prefix for Docker Compose resources (network, volumes) |
| `DOMAIN_NAME` | `amalangu.42.fr` | Domain served by Nginx, embedded in the TLS cert SAN/CN, and used as the WordPress site URL |
| `LOGIN` | `amalangu` | Username for both the MariaDB user and the WordPress editor account. Must match `[a-zA-Z0-9_]+` |
| `WP_PORT` | `9000` | Internal PHP-FPM FastCGI listening port |
| `WP_ADMIN_NAME` | `boss` | WordPress administrator username (per 42 rules, must **not** contain `admin` or `administrator`) |
| `WP_ADMIN_MAIL` | `admin@example.com` | WordPress administrator email |
| `WP_USER_MAIL` | `login@student.42lyon.fr` | WordPress editor email |
| `MYSQL_PORT` | `3306` | Internal MariaDB TCP port |
| `MYSQL_NAME` | `db` | MariaDB database name. Must match `[a-zA-Z0-9_]+` |
| `NGINX_PORT` | `443` | HTTPS port exposed on the host by Nginx |
| `DB_USER_PWD` | `../secrets/db_user_pwd` | Path to MariaDB user password file (relative to `srcs/docker-compose.yml`) |
| `DB_ROOT_PWD` | `../secrets/db_root_pwd` | Path to MariaDB root password file |
| `WP_ADMIN_PWD` | `../secrets/wp_admin_pwd` | Path to WordPress admin password file |
| `WP_LOGIN_PWD` | `../secrets/wp_login_pwd` | Path to WordPress editor password file |

#### `secrets/` Files

Write a password into each of the four files inside `secrets/`:

- `secrets/db_root_pwd` — MariaDB `root@localhost` password
- `secrets/db_user_pwd` — MariaDB application user (`LOGIN`) password
- `secrets/wp_admin_pwd` — WordPress administrator (`WP_ADMIN_NAME`) password
- `secrets/wp_login_pwd` — WordPress editor (`LOGIN`) password

---

## Project Structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── docs/imgs/                              # Documentation diagrams and screenshots
├── secrets.tofill/                         # Empty template files for Docker secrets
└── srcs/
    ├── .env.example                        # Template environment variables
    ├── docker-compose.yml                  # Service, network, volume, and secret definitions
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile                  # Alpine 3.23 + MariaDB server & client
        │   ├── conf/my.cnf                 # MariaDB server config template
        │   └── tools/
        │       ├── entrypoint.sh           # Config render, DB init, bootstrap, exec mariadbd
        │       └── healthcheck.sh          # TCP mariadb-admin ping
        ├── wordpress/
        │   ├── Dockerfile                  # Alpine 3.23 + PHP 8.5 FPM + WP 7.0 + WP-CLI 2.12.0
        │   ├── conf/www.conf               # PHP-FPM pool template (user=www, pm=dynamic)
        │   └── tools/
        │       └── entrypoint.sh           # Config render, WP-CLI setup, exec php-fpm85 -F
        └── nginx/
            ├── Dockerfile                  # Alpine 3.23 + Nginx + OpenSSL + curl
            ├── conf/
            │   ├── default.conf            # HTTPS TLSv1.3 server block + FastCGI proxy template
            │   └── req.conf                # OpenSSL X.509 certificate request template
            └── tools/
                ├── entrypoint.sh           # Self-signed cert generation, config render, exec nginx
                └── healthcheck.sh          # Local curl HTTPS check against DOMAIN_NAME
```

---

## Architecture & Service Implementation

All three images inherit from `alpine:3.23`, use `pull_policy: build`, run their main daemon in the foreground via `exec` (PID 1), have `restart: unless-stopped`, and render `.template` configuration files dynamically at container startup using environment variables.

### Startup Dependency Chain

`docker-compose.yml` enforces ordered startup using Docker healthchecks:

```text
mariadb (healthy) ──▶ wordpress (healthy) ──▶ nginx (healthy)
```

### MariaDB (`srcs/requirements/mariadb/`)

- **Packages:** `mariadb`, `mariadb-client`.
- **Configuration:** [`conf/my.cnf`](srcs/requirements/mariadb/conf/my.cnf) is copied to `/etc/my.cnf.d/mariadb-server.cnf.template` and rendered at runtime with `PORT` and socket path `/var/lib/mariadb/$DB_NAME/$DB_NAME.sock`, binding to `0.0.0.0`.
- **Entrypoint ([`tools/entrypoint.sh`](srcs/requirements/mariadb/tools/entrypoint.sh)):**
  - Runs with `set -eou pipefail`.
  - Verifies `/run/secrets/db_root_pwd` and `/run/secrets/db_user_pwd` exist, validates `DB_NAME` and `LOGIN` characters, and SQL-escapes single quotes in passwords.
  - On first run (missing `/var/lib/mariadb/mysql`), creates `$DATADIR/$DB_NAME`, sets `mysql:mysql` ownership, and runs `mariadb-install-db --skip-test-db`.
  - On first bootstrap (missing `/var/lib/mariadb/.bootstrap_complete`), pipes SQL statements into `mariadbd --bootstrap --skip-grant-tables=0` to set the `root@localhost` password, create `$DB_NAME`, create `$LOGIN@'%'` with `ALL PRIVILEGES` on `$DB_NAME.*`, and creates the `.bootstrap_complete` sentinel file.
  - Launches `exec mariadbd --skip-networking=0`.
- **Healthcheck ([`tools/healthcheck.sh`](srcs/requirements/mariadb/tools/healthcheck.sh)):** Runs every 10s (`start-period=5s`, `timeout=3s`) via `mariadb-admin ping --protocol=tcp --host=127.0.0.1`.

### WordPress & PHP-FPM (`srcs/requirements/wordpress/`)

- **Packages:** `php85`, `php85-phar`, `php85-fpm`, `php85-mysqli`, `php85-mbstring`, `php85-gd`, `wget`. Creates a `/usr/bin/php` symlink to `/usr/bin/php85` and a dedicated `www` user/group.
- **Software versions pinned at build time:** WordPress `7.0` extracted into `/var/www/wordpress` and WP-CLI `v2.12.0` installed at `/usr/bin/wp`.
- **Configuration:** [`conf/www.conf`](srcs/requirements/wordpress/conf/www.conf) configures the `[www]` pool (`user = www`, `group = www`, `pm = dynamic`, `max_children = 5`, `start_servers = 2`, `min_spare_servers = 1`, `max_spare_servers = 3`) and substitutes `WP_PORT_PLACEHOLDER` with `WP_PORT`.
- **Entrypoint ([`tools/entrypoint.sh`](srcs/requirements/wordpress/tools/entrypoint.sh)):**
  - Verifies `/run/secrets/db_user_pwd`, `/run/secrets/wp_admin_pwd`, and `/run/secrets/wp_login_pwd`.
  - Idempotently runs `wp config create` (if `wp-config.php` is absent), `wp core install` (if WordPress is not yet installed), and `wp user create` with `--role=editor` (if `$LOGIN` does not exist).
  - Validates configuration with `php-fpm85 -t` and launches `exec php-fpm85 -F`.
- **Healthcheck:** Runs every 10s (`start-period=5s`, `timeout=3s`) checking `pgrep -x php-fpm85`.

### Nginx (`srcs/requirements/nginx/`)

- **Packages:** `nginx`, `openssl`, `curl`.
- **TLS Certificate:** On startup, if `/etc/ssl/cert.key` or `/etc/ssl/cert.crt` is missing, renders [`conf/req.conf`](srcs/requirements/nginx/conf/req.conf) with `DOMAIN_NAME` (for both `CN` and `subjectAltName` `DNS.1`) and generates a self-signed 2048-bit RSA X.509 certificate valid for 365 days.
- **Configuration:** [`conf/default.conf`](srcs/requirements/nginx/conf/default.conf) enforces `ssl_protocols TLSv1.3;`, serves static files from `/var/www/wordpress` (mounted read-only from `wordpress-data`), and forwards `.php` requests to `wordpress:${WP_PORT}` via FastCGI. Only `${NGINX_PORT}:${NGINX_PORT}` (port `443`) is published to the host in `docker-compose.yml`.
- **Entrypoint ([`tools/entrypoint.sh`](srcs/requirements/nginx/tools/entrypoint.sh)):** Generates the certificate if needed, renders `default.conf`, validates with `nginx -t`, and launches `exec nginx -g "daemon off;"`.
- **Healthcheck ([`tools/healthcheck.sh`](srcs/requirements/nginx/tools/healthcheck.sh)):** Runs every 10s (`start-period=15s`, `timeout=5s`), sending an HTTPS request via `curl --insecure --fail --resolve "$DOMAIN_NAME:$NGINX_PORT:127.0.0.1"`.

---

## Building and Launching the Project

### Makefile Targets

The root [`Makefile`](Makefile) wraps `docker compose -f srcs/docker-compose.yml`:

| Target | Command Executed | Purpose |
|---|---|---|
| `make` / `make all` | Alias for `up` | Full check, build, and startup |
| `make check` | Checks `srcs/.env`, `secrets/`, and `compose config --quiet` | Validates prerequisites and Compose syntax |
| `make dirs` | `mkdir -p ~/data/mariadb ~/data/wordpress` | Ensures bind-mount host directories exist |
| `make build` | `check` + `compose build` | Builds all images without starting containers |
| `make up` | `check` + `dirs` + `compose up -d --build --wait` | Builds images, starts containers, waits for healthchecks |
| `make down` | `check` + `compose down` | Stops and removes containers and the `shared` network |
| `make stop` | `check` + `compose stop` | Stops running containers |
| `make start` | `check` + `compose start --wait` | Starts stopped containers and waits for healthchecks |
| `make restart` | `check` + `compose restart` | Restarts all containers |
| `make logs` | `compose logs --follow` | Streams logs from all services |
| `make ps` | `compose ps --all` | Shows container state and health status |
| `make clean` | `check` + `compose down -v --remove-orphans` | Removes containers, network, orphans, and volume objects (keeps `~/data/*`) |
| `make fclean` | `clean` + `sudo rm -rf -- ~/data/mariadb ~/data/wordpress` | Complete reset including host persistent data |
| `make re` | `clean` + `up` | Rebuilds and restarts the stack while preserving `~/data/*` |

### Direct Docker Compose Commands

When iterating on a single service during development:

```sh
# Rebuild and recreate only one service without restarting dependencies
docker compose -f srcs/docker-compose.yml up -d --build --no-deps nginx

# Inspect the resolved Compose configuration (with .env variables expanded)
docker compose -f srcs/docker-compose.yml config
```

---

## Managing Containers, Networks, and Debugging

### Inspecting Runtime State

```sh
# Container status & health
make ps

# Follow logs for a specific service
docker compose -f srcs/docker-compose.yml logs -f wordpress

# Inspect healthcheck history of a container
docker inspect --format '{{json .State.Health}}' mariadb | python3 -m json.tool

# Inspect the internal Docker bridge network and connected containers
docker network inspect inception_shared
```

### Interactive Debugging Inside Containers

Open a shell in any container:

```sh
docker exec -it mariadb sh
docker exec -it wordpress sh
docker exec -it nginx sh
```

Useful service-specific checks:

```sh
# Query MariaDB directly (will prompt for secrets/db_user_pwd)
docker exec -it mariadb mariadb -u <LOGIN> -p <MYSQL_NAME> -e "SHOW TABLES;"

# Run WP-CLI commands inside the WordPress container
docker exec -u www wordpress wp user list
docker exec -u www wordpress wp option get siteurl

# Test Nginx configuration syntax
docker exec nginx nginx -t

# Inspect the TLSv1.3 certificate served by Nginx
openssl s_client -connect <DOMAIN_NAME>:443 -servername <DOMAIN_NAME> -tls1_3 </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
```

---

## Data Persistence

Persistent data is stored on the host under `$(HOME)/data/` and mapped into containers through two named Docker volumes defined in [`srcs/docker-compose.yml`](srcs/docker-compose.yml):

| Docker Volume | Host Path (`device`) | Container Mount Point | Access Mode | Contents |
|---|---|---|---|---|
| `mariadb-data` | `~/data/mariadb` | `mariadb:/var/lib/mariadb` | Read-Write | MariaDB system tables, application database (`$MYSQL_NAME`), socket, and `.bootstrap_complete` marker |
| `wordpress-data` | `~/data/wordpress` | `wordpress:/var/www/wordpress` | Read-Write | WordPress core files, `wp-config.php`, themes, plugins, uploads |
| `wordpress-data` | `~/data/wordpress` | `nginx:/var/www/wordpress` | Read-Only (`:ro`) | Static assets served directly by Nginx |

### Persistence Behavior

- **Stopping or rebuilding (`make stop`, `make down`, `make clean`, `make re`):** Because the named volumes use `driver: local` with `o: bind` targeting host paths, removing the Docker volume definitions does **not** erase the files inside `~/data/mariadb` and `~/data/wordpress`. Database state and WordPress files survive container rebuilds and restarts.
- **Full wipe (`make fclean`):** Explicitly removes `~/data/mariadb` and `~/data/wordpress` using `sudo rm -rf` (required because files inside those directories are owned by the container `mysql` and `www` UIDs). The next `make up` performs a clean MariaDB bootstrap and WordPress installation.
- **Inspecting volumes on the host:**

```sh
docker volume ls
docker volume inspect inception_mariadb-data inception_wordpress-data
ls -la ~/data/mariadb ~/data/wordpress
```
