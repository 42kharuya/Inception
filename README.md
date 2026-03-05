
*This project has been created as part of the 42 curriculum by kharuya.*

# Inception

## Description

Inception is a small Docker-based infrastructure that runs a WordPress site behind an NGINX reverse proxy with TLS, backed by a MariaDB database.

The goal of the project is to practice system administration concepts with containers: building images from scratch (Debian), wiring services together via a dedicated Docker network, persisting data with volumes, and handling sensitive information using Docker secrets.

### What is included

- `mariadb` container: database service (not exposed to the host)
- `wordpress` container: PHP-FPM + WP-CLI to bootstrap WordPress (not exposed to the host)
- `nginx` container: HTTPS endpoint on port 443 (the only exposed service)
- A dedicated bridge network (`inception_network`) for container-to-container communication
- Two persistent volumes (DB + WordPress files) stored under `/home/<login>/data`
- Docker secrets for passwords

## Instructions

### Prerequisites

- Linux machine (usually a VM for the 42 subject)
- Docker Engine and Docker Compose v2 (`docker compose`)
- GNU Make

Check versions:

```bash
docker --version
docker compose version
make --version
```

### Configure the project

1) Edit the environment file:

- `srcs/.env`

At minimum, set:

- `LOGIN=<your_login>`
- `DOMAIN_NAME=<your_login>.42.fr`

2) Configure secrets (passwords) under `secrets/`:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/credentials.txt` (must define `WP_ADMIN_PASSWORD` and `WP_USER_PASSWORD`)

Security note: keep real secret values out of version control (e.g., using `.gitignore`) and recreate them locally.

3) Ensure your domain resolves to the host/VM running Docker.

Example with `/etc/hosts`:

```bash
sudo sh -c 'echo "<VM_IP>  <your_login>.42.fr" >> /etc/hosts'
```

### Build and run

From the repository root:

```bash
make up
```

Useful lifecycle commands:

```bash
make down
make restart
make clean
make fclean
make rebuild
```

### Access

- Website: `https://<DOMAIN_NAME>/`
- Admin panel: `https://<DOMAIN_NAME>/wp-admin/`

NGINX uses a self-signed certificate, so your browser will show a warning for local testing.

## Project design choices

### Why Docker here

Docker makes it practical to:

- Build and run reproducible services with explicit dependencies
- Keep NGINX/WordPress/MariaDB isolated yet connected through a private network
- Persist data outside containers while allowing containers to be rebuilt anytime

### Implementation highlights (from the source)

- Images are built from `debian:bookworm` in:
	- `srcs/requirements/mariadb/Dockerfile`
	- `srcs/requirements/wordpress/Dockerfile`
	- `srcs/requirements/nginx/Dockerfile`
- Startup is handled by idempotent entrypoints in `srcs/requirements/*/tools/entrypoint.sh`:
	- MariaDB initializes database/users on first run.
	- WordPress downloads/configures/installs on first run (using WP-CLI).
	- NGINX renders config from a template and generates a self-signed cert for `DOMAIN_NAME`.

## Required comparisons

### Virtual Machines vs Docker

- **VMs** virtualize hardware: each VM runs its own kernel and full OS, which increases overhead but provides strong isolation boundaries.
- **Docker containers** share the host kernel: they start faster, use fewer resources, and are ideal for packaging services, but isolation is lighter than a VM.
- In this project, Docker is used to compose multiple services in a single host/VM while keeping them isolated at the process/network/filesystem level.

### Secrets vs Environment Variables

- **Environment variables** are easy for configuration but may be exposed via `docker inspect`, logs, process listings, or crash reports.
- **Docker secrets** are mounted as files under `/run/secrets/*` and are designed specifically for sensitive values.
- This project uses `srcs/.env` for non-sensitive configuration and Compose secrets for passwords.

### Docker Network vs Host Network

- With a dedicated **Docker bridge network**, services can talk using DNS names (`mariadb`, `wordpress`) without exposing internal ports to the host.
- **Host networking** removes network isolation and can cause port conflicts; it is also forbidden by the subject.
- This project uses a custom bridge network called `inception_network`.

### Docker Volumes vs Bind Mounts

- **Docker volumes** are managed by Docker and are the recommended way to persist container data.
- **Bind mounts** map an arbitrary host path into a container; they are powerful but tie you to host filesystem paths and permissions.
- This project defines *named volumes* (`DB`, `WordPress`) and configures them to store data under `/home/${LOGIN}/data/*` using the local driver options.

## Resources

### References

- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- Docker volumes: https://docs.docker.com/storage/volumes/
- Docker secrets (Compose): https://docs.docker.com/compose/use-secrets/
- NGINX TLS configuration: https://nginx.org/en/docs/http/configuring_https_servers.html
- WordPress WP-CLI: https://wp-cli.org/
- MariaDB docs: https://mariadb.com/kb/en/documentation/

### AI usage disclosure

AI was used to help draft and structure the English documentation (README/DEV_DOC/USER_DOC) based on the repository’s actual Compose configuration, Dockerfiles, and entrypoint scripts. All commands, paths, and environment variables were cross-checked against the code in this repository.

No application logic was generated or modified by AI as part of the infrastructure implementation.

