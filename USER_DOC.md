
# USER_DOC — User / Administrator Documentation

This document explains how to operate the Inception stack as an end user or administrator.

## 1) What services are provided?

This stack provides a standard WordPress website behind TLS:

- **Website (HTTPS)**: served by **nginx** on port **443**.
- **WordPress application**: runs on **PHP-FPM** inside the **wordpress** container (internal port **9000**).
- **Database**: **mariadb** container (internal port **3306**).

Only nginx is exposed to the host. WordPress and MariaDB are reachable only inside the Docker network.

## 2) Start / stop the project

All commands are run from the repository root.

### 2.1 Create required secret files (first-time setup)

Before running `make up`, create the following files:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/credentials.txt`

Write them using one of the following patterns.

#### Pattern A: set values manually

Use this when you want deterministic passwords (for local testing) or you want to choose them yourself.

```bash
mkdir -p secrets

# Create/edit each file (examples)
echo -n 'your_db_root_password_here' > secrets/db_root_password.txt
echo -n 'your_db_app_password_here'  > secrets/db_password.txt

# credentials.txt must be KEY=VALUE lines (no spaces around '=')
cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_PASSWORD=your_wordpress_admin_password_here
WP_USER_PASSWORD=your_wordpress_user_password_here
EOF

# Restrict permissions
chmod 600 secrets/*.txt
```

#### Pattern B: generate values using OpenSSL

Recommended: generate strong random passwords and restrict permissions.

```bash
mkdir -p secrets

# Restrictive permissions for newly created files in this shell
umask 077

# Generate DB passwords (single line)
openssl rand -base64 32 | tr -d '\n' > secrets/db_root_password.txt
openssl rand -base64 32 | tr -d '\n' > secrets/db_password.txt

# Generate WordPress passwords (credentials.txt must be KEY=VALUE lines)
echo "WP_ADMIN_PASSWORD=$(openssl rand -base64 32)" > secrets/credentials.txt
echo "WP_USER_PASSWORD=$(openssl rand -base64 32)" >> secrets/credentials.txt

chmod 600 secrets/*.txt
```

Notes:

- `credentials.txt` must be shell-compatible (no spaces around `=`).
- If you change these secrets after a successful first install, you may need a clean reprovision: `make fclean && make up`.

### Start

```bash
make up
```

This will:

- Create persistent host directories under `/home/${LOGIN}/data`.
- Build images and start containers in the background.

### Stop

```bash
make down
```

### Restart

```bash
make restart
```

### Remove containers and volumes

```bash
make clean
```

### Full reset (also deletes saved data)

```bash
make fclean
```

## 3) Access the website and admin panel

### 3.1 Domain name

The site URL is driven by `DOMAIN_NAME` in `srcs/.env` (commonly `<login>.42.fr`).

Make sure your domain resolves to the machine running Docker (VM IP is typical). Example:

```bash
sudo sh -c 'echo "127.0.0.1  <login>.42.fr" >> /etc/hosts'
```

### 3.2 Website

Open in your browser:

- `https://<DOMAIN_NAME>/`

Note: nginx generates a **self-signed certificate** at container start. Your browser will show a security warning; you can proceed for local testing.

### 3.3 WordPress admin panel

Open:

- `https://<DOMAIN_NAME>/wp-admin/`

Log in with the admin credentials described in the next section.

## 4) Locate and manage credentials

This project intentionally separates **non-secret configuration** (environment variables) and **passwords** (Docker secrets).

### 4.1 Non-secret config (environment)

File: `srcs/.env`

Contains:

- Domain name and site metadata
- Database name / username
- WordPress usernames + emails

### 4.2 Passwords (Docker secrets)

Folder: `secrets/`

Security note: these files should be treated as local-only and should not contain real credentials in a public repository.

- `secrets/db_root_password.txt`: MariaDB root password
- `secrets/db_password.txt`: MariaDB application user password
- `secrets/credentials.txt`: WordPress passwords as variables:
	- `WP_ADMIN_PASSWORD=...`
	- `WP_USER_PASSWORD=...`

Inside containers, these are mounted as files under `/run/secrets/`.

### 4.3 Rotating credentials (safe procedure)

Because WordPress and MariaDB data is persisted on disk, simply changing secret files might not be enough to fully “re-provision” users. Recommended approaches:

- **Change WordPress user passwords via WordPress admin UI** (preferred for a running site).
- For a complete clean re-install of both DB and WordPress:

```bash
make fclean
make up
```

This deletes `/home/${LOGIN}/data` and forces the entrypoints to bootstrap from scratch.

## 5) Check that services are running correctly

### 5.1 Basic status

```bash
docker compose -f srcs/docker-compose.yml ps
```

You should see three services: `mariadb`, `wordpress`, `nginx`.

### 5.2 Healthchecks

This project configures healthchecks for MariaDB and WordPress. nginx starts only after WordPress is healthy.

```bash
docker inspect --format '{{.State.Health.Status}}' mariadb
docker inspect --format '{{.State.Health.Status}}' wordpress
```

### 5.3 Logs

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

If something fails, check service-specific logs:

```bash
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f nginx
```

### 5.4 HTTP(S) check from CLI

Self-signed TLS requires `-k` (insecure) for curl:

```bash
curl -kI https://<DOMAIN_NAME>/
```

Expected: an HTTP response (usually `200`/`301`/`302`).

## 6) Where is my data stored?

The stack persists data on the Docker host under:

- Database files: `/home/${LOGIN}/data/DB`
- WordPress files: `/home/${LOGIN}/data/WordPress`

These directories are used by named volumes `DB` and `WordPress` configured in Compose.

