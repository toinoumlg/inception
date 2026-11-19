# User Documentation

This guide explains how to operate, access, and verify the **Inception** infrastructure as an end user or site administrator.

If you are setting up the virtual machine, Docker Engine, or repository from scratch, refer to [`DEV_DOC.md`](DEV_DOC.md) first.

---

## Services Provided by the Stack

The infrastructure runs three containerized services connected over a private Docker network (`shared`):

| Service | Container Name | Role | Accessible From Host? |
|---|---|---|---|
| **Nginx** | `nginx` | Reverse proxy and HTTPS entry point (TLSv1.3, self-signed certificate). Serves static WordPress files and proxies PHP requests to WordPress. | Yes — port `443` (`NGINX_PORT`) |
| **WordPress + PHP-FPM** | `wordpress` | Runs WordPress 7.0 via PHP-FPM 8.5, serving the public website and the administration dashboard. | No (internal port `9000`) |
| **MariaDB** | `mariadb` | Relational database storing all WordPress posts, pages, users, and site settings. | No (internal port `3306`) |

---

## Starting and Stopping the Project

All day-to-day operations are run from the root of the repository using `make`.

> **Before starting for the first time:** ensure that `srcs/.env` and the `secrets/` directory have been created and filled in, and that your configured `DOMAIN_NAME` resolves to `127.0.0.1` in `/etc/hosts` (see [`DEV_DOC.md`](DEV_DOC.md)).

### Start the Stack

```sh
make
# or explicitly:
make up
```

This validates your configuration, creates the persistent host directories (`~/data/mariadb` and `~/data/wordpress`), builds the Docker images if needed, starts the services in order (`mariadb` -> `wordpress` -> `nginx`), and waits until all healthchecks report healthy.

### Stop, Pause, and Restart

| Command | Effect | Preserves Data? |
|---|---|---|
| `make stop` | Pauses running containers without removing them | Yes |
| `make start` | Resumes previously stopped containers and waits for healthchecks | Yes |
| `make restart` | Restarts all running containers | Yes |
| `make down` | Stops and removes containers and the Docker network | Yes |
| `make clean` | Stops and removes containers, network, named volume definitions, and orphans | Yes (`~/data/*` remains intact) |
| `make re` | Runs `make clean` followed by `make up` (rebuilds and restarts) | Yes |
| `make fclean` | Runs `make clean` **and permanently deletes** `~/data/mariadb` and `~/data/wordpress` | **No — wipes database and site files** |

> **Warning:** Only run `make fclean` when you want a completely fresh WordPress and MariaDB installation. It deletes all stored posts, users, uploads, and database records.

---

## Accessing the Website and Administration Panel

### Public Website

Open your browser and navigate to:

```text
https://<DOMAIN_NAME>
```

For example, if `DOMAIN_NAME=amalangu.42.fr` in `srcs/.env`:

```text
https://amalangu.42.fr
```

#### Self-Signed TLS Certificate Notice

Because this stack uses a locally generated self-signed TLSv1.3 certificate (created automatically by OpenSSL inside the `nginx` container), your browser will display a security warning on the first visit (for example, *Potential Security Risk Ahead* in Firefox or *Your connection is not private* in Chromium).

This is expected for a local self-signed certificate. Click **Advanced** -> **Accept the Risk and Continue** (or **Proceed**) to load the site.

### WordPress Administration Panel

To manage pages, posts, themes, plugins, and users, open:

```text
https://<DOMAIN_NAME>/wp-admin
```

Two WordPress accounts are automatically provisioned on the first startup:

| Role | Username Source | Password Source | Permissions |
|---|---|---|---|
| **Administrator** | `WP_ADMIN_NAME` in `srcs/.env` | `secrets/wp_admin_pwd` | Full site management (themes, plugins, users, settings) |
| **Editor** | `LOGIN` in `srcs/.env` | `secrets/wp_login_pwd` | Create, edit, publish, and manage posts and pages |

---

## Locating and Managing Credentials

Credentials and settings are split into two locations (both excluded from Git via `.gitignore`):

### 1. Configuration Parameters (`srcs/.env`)

Created from [`srcs/.env.example`](srcs/.env.example). Contains non-sensitive settings:

- `DOMAIN_NAME`: Domain used by Nginx, the TLS certificate, and WordPress (`<login>.42.fr`).
- `LOGIN`: Username for both the MariaDB application user and the WordPress editor account.
- `WP_ADMIN_NAME`: Username for the WordPress administrator account (must not contain `admin` or `administrator`).
- `WP_ADMIN_MAIL` / `WP_USER_MAIL`: Email addresses for the WordPress admin and editor accounts.
- `MYSQL_NAME`, `MYSQL_PORT`, `WP_PORT`, `NGINX_PORT`: Database name and service ports.
- `DB_USER_PWD`, `DB_ROOT_PWD`, `WP_ADMIN_PWD`, `WP_LOGIN_PWD`: Paths to the secret files relative to `srcs/docker-compose.yml`.

### 2. Passwords (`secrets/`)

Created from [`secrets.tofill/`](secrets.tofill/). Each file contains a single plain-text password:

| File | Used By | Purpose |
|---|---|---|
| `secrets/db_root_pwd` | MariaDB | Database `root@localhost` password |
| `secrets/db_user_pwd` | MariaDB & WordPress | Database password for the `LOGIN` user |
| `secrets/wp_admin_pwd` | WordPress | WordPress administrator (`WP_ADMIN_NAME`) password |
| `secrets/wp_login_pwd` | WordPress | WordPress editor (`LOGIN`) password |

### Updating Credentials

- **WordPress user passwords:** Once the site is running, change user passwords directly from the WordPress dashboard (**Users -> Profile / All Users**), and update the matching file in `secrets/` if you want to keep them aligned for future fresh deployments.
- **Database or initial setup changes:** MariaDB and WordPress only read initial credentials during first-time initialization (when `~/data/mariadb` and `~/data/wordpress` are empty). To re-initialize the entire stack with new values from `srcs/.env` and `secrets/`, run:

```sh
make fclean && make up
```

---

## Checking That Services Are Running Correctly

### 1. Check Container Status and Health

```sh
make ps
```

All three containers (`mariadb`, `wordpress`, `nginx`) should show status `Up ... (healthy)`.

### 2. Inspect Service Logs

Follow live logs across all services:

```sh
make logs
```

Or inspect a single service:

```sh
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### 3. Verify HTTPS and TLSv1.3 Connectivity

Use `curl` from the host (`-k` accepts the self-signed certificate):

```sh
curl -kI --tlsv1.3 https://<DOMAIN_NAME>
```

A healthy deployment returns an `HTTP/1.1 200 OK` (or `HTTP/2 200`) response from Nginx.

You can also verify that older TLS protocols are rejected:

```sh
curl -kI --tls-max 1.2 https://<DOMAIN_NAME>
```

This command should fail with a TLS handshake error, confirming that only TLSv1.3 is enabled.

### 4. Run Built-In Healthchecks Manually

```sh
docker exec mariadb /healthcheck.sh && echo "MariaDB OK"
docker exec wordpress pgrep -x php-fpm85 >/dev/null && echo "WordPress PHP-FPM OK"
docker exec nginx /healthcheck.sh && echo "Nginx OK"
```

---

## Common Issues

| Symptom | Likely Cause | Resolution |
|---|---|---|
| `srcs/.env not set` or `secrets/* not set` | Missing config file or secrets directory | Copy `srcs/.env.example` to `srcs/.env` and `secrets.tofill` to `secrets/`, then fill them in |
| Browser cannot resolve `<DOMAIN_NAME>` | Missing `/etc/hosts` entry | Add `127.0.0.1 <DOMAIN_NAME>` to `/etc/hosts` |
| Port `443` already in use | Another web server is bound to port 443 on the host | Stop the conflicting host service (e.g., `sudo systemctl stop nginx apache2`) |
| `mariadb` exits with `invalid database name` or `invalid login name` | `MYSQL_NAME` or `LOGIN` contains invalid characters | Use only letters, digits, and underscores (`[a-zA-Z0-9_]`) in `srcs/.env` |
| Changes to passwords in `secrets/` had no effect | Existing persistent data in `~/data/` skips bootstrap | Update passwords via WordPress/MariaDB directly, or run `make fclean && make up` for a clean rebuild |
