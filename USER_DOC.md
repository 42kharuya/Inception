## USER_DOC.md

### What services are provided
This stack provides:
- HTTPS web entrypoint (NGINX on port 443)
- WordPress application (PHP-FPM)
- MariaDB database

### Start and stop
- Start/build all services: `make up`
- Stop services: `make down`
- Remove containers + volumes: `make clean`
- Full cleanup including host data: `make fclean`

### Access website and admin panel
1. Ensure your host maps domain to local IP:
   - `127.0.0.1 kharuya.42.fr`
2. Open browser:
   - Site: `https://kharuya.42.fr`
   - Admin: `https://kharuya.42.fr/wp-admin`

### Credentials location and management
- Non-secret config is in [srcs/.env](srcs/.env).
- Passwords are in [secrets](secrets) files:
  - DB root password
  - DB app password
  - WordPress admin/user passwords (`credentials.txt`)

Do not publish secrets to remote repositories.

### Check services are healthy
- `docker compose -f srcs/docker-compose.yml ps`
- `docker compose -f srcs/docker-compose.yml logs -f`
- `curl -kI https://kharuya.42.fr`

Expected result: HTTPS responds on port 443 and WordPress login page is reachable.
