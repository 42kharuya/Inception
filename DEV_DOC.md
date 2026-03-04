## DEV_DOC.md

### 1) Set up environment from scratch
#### Prerequisites
- Linux VM
- Docker Engine + Docker Compose plugin
- `sudo` privileges

#### Required files
- Compose and Dockerfiles under [srcs](srcs)
- Environment variables in [srcs/.env](srcs/.env)
- Runtime secrets under [secrets](secrets):
  - `db_root_password.txt`
  - `db_password.txt`
  - `credentials.txt`

`credentials.txt` must export:
- `WP_ADMIN_PASSWORD`
- `WP_USER_PASSWORD`

### 2) Build and launch with Makefile + Compose
- `make up`: creates `/home/<login>/data/*`, builds images, starts containers
- `make down`: stops/removes containers
- `make clean`: `down -v`
- `make fclean`: `clean` + removes `/home/<login>/data`
- `make rebuild`: rebuild images without cache

Main command wrapper is defined in [Makefile](Makefile#L6).

### 3) Useful operations
- Check container status: `docker compose -f srcs/docker-compose.yml ps`
- Follow logs: `docker compose -f srcs/docker-compose.yml logs -f`
- Rebuild one service: `docker compose -f srcs/docker-compose.yml build <service>`
- Inspect network: `docker network inspect inception_network`
- Inspect volumes: `docker volume ls`

### 4) Data storage and persistence
- Database data: `/home/<login>/data/DB`
- WordPress files: `/home/<login>/data/WordPress`

Volume declarations live in [srcs/docker-compose.yml](srcs/docker-compose.yml#L52-L66).
They persist outside container lifecycle and survive restarts/recreation.

### 5) Service-specific notes
- MariaDB initialization logic: [srcs/requirements/mariadb/tools/entrypoint.sh](srcs/requirements/mariadb/tools/entrypoint.sh)
- WordPress bootstrap logic: [srcs/requirements/wordpress/tools/entrypoint.sh](srcs/requirements/wordpress/tools/entrypoint.sh)
- TLS reverse proxy config: [srcs/requirements/nginx/conf/nginx.conf](srcs/requirements/nginx/conf/nginx.conf)
