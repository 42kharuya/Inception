
# DEV_DOC — Developer Documentation

This document explains how to set up, build, run, and operate this Inception stack as a developer.

This file is organized to match the required developer-doc topics:

- Set up the environment from scratch (prereqs, config files, secrets)
- Build and launch using the Makefile and Docker Compose
- Commands to manage containers and volumes
- Where data is stored and how it persists

## 1) What this project is (developer view)

This repository defines a minimal WordPress infrastructure using Docker Compose:

- **nginx**: the only public entrypoint, serves HTTPS on port 443 and forwards PHP requests to PHP-FPM.
- **wordpress**: PHP-FPM + WP-CLI; downloads/configures WordPress on first run.
- **mariadb**: database backend.

Key implementation files:

- `srcs/docker-compose.yml`: Compose stack definition (services, volumes, network, secrets, healthchecks).
- `Makefile`: the project’s main interface (`make up`, `make down`, etc.).
- `srcs/requirements/*/Dockerfile`: per-service images built from Debian bookworm.
- `srcs/requirements/*/tools/entrypoint.sh`: runtime initialization logic (idempotent setup).

## 2) Set up the environment from scratch

### 2.1 Prerequisites (system / OS)

- Linux host (the project stores persistent data under `/home/<LOGIN>/data`).
- A VM is typically used for the 42 evaluation.

### 2.2 Prerequisites (required software)

- Docker Engine
- Docker Compose v2 (the `docker compose` subcommand)
- GNU Make

Quick checks:

```bash
docker --version
docker compose version
make --version
```

### 2.3 Domain name resolution (required for TLS + WordPress URLs)

The stack expects a domain name (commonly `<login>.42.fr`) that resolves to the VM/host where Docker runs.

For local testing, you can map the domain to your VM IP (recommended) or to `127.0.0.1` (only if you access from the same host):

```bash
sudo sh -c 'echo "<VM_IP>  <login>.42.fr" >> /etc/hosts'
```

### 2.4 Configuration files and secrets

#### 2.4.1 Environment variables (`srcs/.env`)

The Makefile and Compose rely on `srcs/.env`.

Important: `LOGIN` is mandatory. The Makefile will stop if it is missing.

Typical variables used by the stack:

- `LOGIN`: your UNIX login; used to build the persistent data path `/home/${LOGIN}/data`.
- `DOMAIN_NAME`: domain served by nginx and used as the WordPress site URL.
- `MYSQL_DATABASE`, `MYSQL_USER`: MariaDB database and user.
- `SITE_TITLE`: WordPress site title.
- `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`: WordPress admin account (username must not contain `admin`, `Admin`, `administrator`, etc. per subject).
- `WP_USER`, `WP_USER_EMAIL`: WordPress “regular” user.

Notes:

- Passwords are intentionally not stored in `srcs/.env` in this implementation; they are read from Docker secrets.

Minimal example (create from scratch):

```bash
cat > srcs/.env << 'EOF'
LOGIN=<your_login>
DOMAIN_NAME=<your_login>.42.fr

MYSQL_DATABASE=inception_db
MYSQL_USER=<your_login>

SITE_TITLE=inception
WP_ADMIN_USER=<admin_user_without_admin_word>
WP_ADMIN_EMAIL=<admin_email>
WP_USER=<your_login>
WP_USER_EMAIL=<user_email>
EOF
```

#### 2.4.2 Docker secrets (`secrets/*`)

Secrets are provided to containers via Docker Compose `secrets:`. They are mounted as files under `/run/secrets/<name>`.

Security note:

- Treat the `secrets/` directory as **local-only**. Do not publish real passwords in a public repository.
- For submissions, it is common to keep secret *values* out of git (for example via `.gitignore`) and recreate them locally.

Secrets used:

- `secrets/db_root_password.txt` → `/run/secrets/db_root_password` (MariaDB root password)
- `secrets/db_password.txt` → `/run/secrets/db_password` (application DB user password)
- `secrets/credentials.txt` → `/run/secrets/credentials` (WordPress passwords as shell variables)

`secrets/credentials.txt` is sourced by the WordPress entrypoint and must define:

- `WP_ADMIN_PASSWORD=...`
- `WP_USER_PASSWORD=...`

Create the required secret files (first-time setup):

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/credentials.txt`

Pattern A (manual values):

```bash
mkdir -p secrets
echo -n '<db_root_password>' > secrets/db_root_password.txt
echo -n '<db_app_password>'  > secrets/db_password.txt

cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_PASSWORD=<wp_admin_password>
WP_USER_PASSWORD=<wp_user_password>
EOF

chmod 600 secrets/*.txt
```

Pattern B (generate using OpenSSL):

```bash
mkdir -p secrets
umask 077

openssl rand -base64 32 | tr -d '\n' > secrets/db_root_password.txt
openssl rand -base64 32 | tr -d '\n' > secrets/db_password.txt

echo "WP_ADMIN_PASSWORD=$(openssl rand -base64 32)" > secrets/credentials.txt
echo "WP_USER_PASSWORD=$(openssl rand -base64 32)" >> secrets/credentials.txt

chmod 600 secrets/*.txt
```

#### 2.4.3 Where secrets are referenced in code

- MariaDB healthcheck reads the root password from `/run/secrets/db_root_password`.
- MariaDB entrypoint exports `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` from the secret files.
- WordPress entrypoint exports `MYSQL_PASSWORD` from `db_password` and loads `WP_ADMIN_PASSWORD` / `WP_USER_PASSWORD` from `credentials`.

## 4) Build & launch (Makefile + Compose)

### 4.1 Default workflow

From the repository root:

```bash
make up
```

What it does:

1) Loads `srcs/.env` (Makefile `-include srcs/.env`).
2) Creates host directories:
	 - `/home/${LOGIN}/data/DB`
	 - `/home/${LOGIN}/data/WordPress`
3) Runs `docker compose -f srcs/docker-compose.yml up -d --build`.

### 4.2 Stop / restart

```bash
make down
make restart
```

### 4.3 Clean / full clean

- Remove containers + named volumes:

```bash
make clean
```

- In this implementation, volumes are backed by host directories under `/home/${LOGIN}/data/*`.
	`make clean` removes the Docker volume objects, but it does not reliably remove the host directories themselves.
	For a guaranteed full wipe of persisted data, use `make fclean`.

- Additionally delete the host data directory `/home/${LOGIN}/data`:

```bash
make fclean
```

### 4.4 Rebuild images without cache

```bash
make rebuild
make up
```

## 5) Operational commands (containers, logs, volumes)

The Makefile wraps Compose, but you can also use `docker compose -f srcs/docker-compose.yml ...` directly.

### 5.1 Inspect running services

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml top
```

### 5.2 Logs

```bash
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

### 5.3 Shell into containers

```bash
docker exec -it nginx sh
docker exec -it wordpress bash
docker exec -it mariadb bash
```

Alternatively (via Compose):

```bash
docker compose -f srcs/docker-compose.yml exec nginx sh
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker compose -f srcs/docker-compose.yml exec mariadb bash
```

### 5.4 Health status

This project uses Compose healthchecks and `depends_on: condition: service_healthy`.

```bash
docker inspect --format '{{json .State.Health}}' mariadb | jq
docker inspect --format '{{json .State.Health}}' wordpress | jq
```

If you do not have `jq`, remove the pipe.

### 5.5 Volumes and where the data lives

Compose defines two named volumes:

- `DB` mounted to `/var/lib/mysql` (MariaDB data dir)
- `WordPress` mounted to `/var/www/html` (WordPress files)

In `srcs/docker-compose.yml`, both are configured with the `local` volume driver and `driver_opts` to store data under:

- `/home/${LOGIN}/data/DB`
- `/home/${LOGIN}/data/WordPress`

Useful commands:

```bash
docker volume ls
docker volume inspect DB
docker volume inspect WordPress
ls -la /home/${LOGIN}/data
```

### 5.6 Network

All services are attached to a dedicated bridge network named `inception_network`.

```bash
docker network ls
docker network inspect inception_network
```

## 6) Service internals (what happens on first run)

### 6.1 MariaDB (`mariadb`)

Entrypoint behavior:

- Reads secrets into `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD`.
- Starts a temporary MariaDB instance (socket-only) to initialize:
	- Creates database `MYSQL_DATABASE` (if missing)
	- Creates user `MYSQL_USER` and grants privileges
	- Sets root password
- Shuts down the bootstrap server and starts `mysqld_safe --user=mysql`.

### 6.2 WordPress (`wordpress`)

Entrypoint behavior:

- Reads secrets (`MYSQL_PASSWORD`, `WP_ADMIN_PASSWORD`, `WP_USER_PASSWORD`).
- Validates required environment variables.
- If `/var/www/html/wp-config.php` is missing:
	- Downloads WordPress (`wp core download`)
	- Creates `wp-config.php` (`wp config create`)
	- Installs the site (`wp core install`)
	- Creates the regular user if missing (`wp user create`)
- Starts PHP-FPM in the foreground on `0.0.0.0:9000`.

### 6.3 nginx (`nginx`)

Entrypoint behavior:

- Requires `DOMAIN_NAME`.
- Generates a self-signed certificate under `/etc/nginx/ssl` with CN/SAN = `DOMAIN_NAME`.
- Renders the nginx config from a template using `envsubst`.
- Starts nginx in the foreground.

## 7) Data persistence and lifecycle

### What persists

- MariaDB data: host directory `/home/${LOGIN}/data/DB`.
- WordPress files (including uploaded media and `wp-config.php`): host directory `/home/${LOGIN}/data/WordPress`.

### What is recreated

- Containers are ephemeral; you can safely recreate them.
- Images can be rebuilt (`make rebuild`).

### What each Make target does to data

- `make down`: stops/removes containers, keeps volumes and host data.
- `make clean`: removes containers and volumes (the Docker volume objects). Host directories may remain.
- `make fclean`: removes everything above and deletes `/home/${LOGIN}/data` (guaranteed data wipe).

### Resetting the stack

If you want to force re-initialization (fresh DB + fresh WP install):

```bash
make fclean
make up
```

