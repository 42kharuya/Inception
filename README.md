*This project has been created as part of the 42 curriculum by kharuya.*

## Description
This repository provides a Docker-based infrastructure for the 42 Inception mandatory part.
It runs three isolated services connected through a custom Docker network:
- NGINX (TLS-only reverse proxy)
- WordPress + PHP-FPM
- MariaDB

The stack persists data with Docker volumes mounted under `/home/<login>/data` and uses Docker secrets for sensitive credentials.

## Instructions
### Prerequisites
- Linux VM
- Docker Engine + Docker Compose plugin
- Domain mapping in `/etc/hosts` (example):
  - `127.0.0.1 kharuya.42.fr`

### Configure
1. Edit [srcs/.env](srcs/.env) values (`LOGIN`, `DOMAIN_NAME`, users/emails).
2. Create/update secret files in [secrets](secrets):
   - `db_root_password.txt`
   - `db_password.txt`
   - `credentials.txt` (must define `WP_ADMIN_PASSWORD` and `WP_USER_PASSWORD`)

### Run
- Start/build: `make up`
- Stop: `make down`
- Stop + remove volumes: `make clean`
- Full cleanup (`/home/<login>/data` included): `make fclean`

## Project description and design choices
- Docker images are built locally from custom Dockerfiles.
- NGINX is the only public entrypoint and listens on 443 with TLSv1.2/1.3.
- PHP-FPM is exposed only inside the Docker network on port 9000.
- MariaDB is internal-only and initialized by entrypoint SQL provisioning.
- Secrets are injected at runtime from `/run/secrets/*`.

### Comparisons
- **Virtual Machines vs Docker**
  - VM: full guest OS, heavier isolation, slower startup.
  - Docker: process-level isolation, lighter, faster, reproducible image builds.
- **Secrets vs Environment Variables**
  - Env vars are easy but can leak in process listings/logs.
  - Docker secrets are file-based, scoped per service, better for passwords.
- **Docker Network vs Host Network**
  - Docker bridge network gives service-level isolation and DNS-based discovery.
  - Host network removes isolation and increases collision/security risk.
- **Docker Volumes vs Bind Mounts**
  - Volumes are managed by Docker and better for portability/lifecycle.
  - Bind mounts tie data layout to host paths and permissions.

## Resources
- Docker docs: https://docs.docker.com/
- Compose spec: https://docs.docker.com/compose/
- NGINX docs: https://nginx.org/en/docs/
- WordPress CLI: https://developer.wordpress.org/cli/commands/
- MariaDB docs: https://mariadb.com/kb/en/documentation/

### How AI was used
AI was used for:
- Reviewing requirement compliance against the project spec.
- Refactoring shell entrypoints for robustness (`set -euo pipefail`, validation, timeout wait).
- Improving readability and consistency in Docker/Compose configuration.
All generated suggestions were manually reviewed and adjusted before applying.
