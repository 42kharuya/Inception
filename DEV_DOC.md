# Developer Documentation - Inception Project

## Project Overview

Inception is a Docker-based infrastructure that sets up a complete WordPress hosting environment with NGINX, PHP-FPM, and MariaDB. This document provides developer-level information for setup, configuration, and maintenance.

## System Requirements

### Prerequisites

- Linux-based operating system (Virtual Machine)
- Docker (19.03+)
- Docker Compose (1.25+)
- Make utility
- Text editor or IDE
- Git
- sudo privileges for system configuration

### Recommended Versions

```bash
# Check versions
docker --version
docker compose version
make --version
```

## Environment Setup

### 1. Initial Configuration

Clone the repository:
```bash
git clone <repository-url>
cd Inception
```

**⚠️ Important:** The `secrets/` directory is excluded from git for security reasons. You must create the secret files manually on your new machine.

### 2. Create Secret Files

**This is a critical step for a fresh setup!**

The project uses Docker Secrets stored in `secrets/` directory. These files are **NOT** included in the git repository for security.

Create the required secret files:

```bash
# Create secrets directory if it doesn't exist
mkdir -p secrets/

# 1. Database Root Password (MariaDB)
echo "your_secure_root_password" > secrets/db_root_password.txt

# 2. Database User Password (MariaDB)
echo "your_secure_db_password" > secrets/db_password.txt

# 3. WordPress Credentials (Admin and User Passwords)
cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_PASSWORD=your_admin_password
WP_USER_PASSWORD=your_user_password
EOF

# Set proper file permissions
chmod 600 secrets/*.txt
```

**Example with secure passwords:**
```bash
# Using openssl to generate strong passwords
openssl rand -base64 32 > secrets/db_root_password.txt
openssl rand -base64 32 > secrets/db_password.txt

# Create credentials with generated passwords
cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_PASSWORD=$(openssl rand -base64 32)
WP_USER_PASSWORD=$(openssl rand -base64 32)
EOF
```

**Important Notes:**
- Each password must be stored in its respective file (one password per file, no variable names)
- These files are in `.gitignore` - they will NEVER be committed to the repository
- Each person or environment should have unique, strong passwords
- **Do NOT commit these files to git** - this will result in immediate project failure

### 3. Configure Environment Variables

Edit `srcs/.env` with your configuration (non-sensitive data only):

```bash
# MariaDB Configuration (sensitive passwords are in secrets/)
MYSQL_DATABASE=inception_db
MYSQL_USER=inception_user

# WordPress Configuration
DOMAIN_NAME=kharuya.42.fr
SITE_TITLE=My WordPress Site

# WordPress User Accounts (passwords are in secrets/)
WP_ADMIN_USER=admin_custom_name
WP_ADMIN_EMAIL=admin@example.com

WP_USER=regular_user
WP_USER_EMAIL=user@example.com
```

### 4. Configure Hosts File

Add the domain to your system's hosts file:

```bash
# Linux/macOS
sudo echo "127.0.0.1 kharuya.42.fr" >> /etc/hosts

# Verify
cat /etc/hosts | grep kharuya
```

### 5. Create Data Directories

The Makefile handles this, but manual creation is:

```bash
mkdir -p /home/kharuya/data/mariadb
mkdir -p /home/kharuya/data/wordpress
chmod 755 /home/kharuya/data/*
```

## Building and Launching

### Building the Infrastructure

```bash
# Build and start all services
make all

# Or build only
make rebuild

# View build progress
docker compose -f srcs/docker-compose.yml build --progress=plain
```

### Understanding the Build Process

1. **NGINX Container**
   - Base: Debian Bookworm
   - Installs: nginx, openssl
   - Generates self-signed SSL certificates
   - Copies nginx.conf configuration

2. **WordPress Container**
   - Base: Debian Bookworm
   - Installs: PHP-FPM, MySQL client, WP-CLI
   - Modifies PHP-FPM to listen on port 9000
   - Runs entrypoint.sh for WordPress setup

3. **MariaDB Container**
   - Base: Debian Bookworm
   - Installs: MariaDB server
   - Configures bind-address for network access
   - Runs entrypoint.sh for database initialization

### Starting Services

```bash
# Start all containers (with automatic build if needed)
make up

# View running containers
docker compose -f srcs/docker-compose.yml ps

# Follow logs
docker compose -f srcs/docker-compose.yml logs -f
```

### Stopping Services

```bash
# Graceful shutdown (preserves data)
make down

# Full cleanup (removes volumes)
make clean

# Complete reset (removes all data)
make fclean
```

## Container Management

### Accessing Container Shells

```bash
# Access WordPress container
docker exec -it wordpress bash

# Access MariaDB container
docker exec -it mariadb bash

# Access NGINX container
docker exec -it nginx bash

# Execute single command
docker exec wordpress wp core version --allow-root
```

### Viewing Logs

```bash
# All services
docker compose -f srcs/docker-compose.yml logs

# Specific service
docker compose -f srcs/docker-compose.yml logs wordpress

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f nginx

# Last N lines
docker compose -f srcs/docker-compose.yml logs --tail=50 mariadb

# Timestamps
docker compose -f srcs/docker-compose.yml logs --timestamps
```

### Container Inspection

```bash
# Container details
docker inspect wordpress

# Network details
docker network inspect inception_network

# Volume details
docker volume inspect wordpress_data
docker volume inspect mariadb_data

# Running processes
docker top wordpress
docker top mariadb
```

### Resource Monitoring

```bash
# Real-time resource usage
docker stats

# Specific container
docker stats wordpress --no-stream

# History
docker inspect --format='{{json .State}}' wordpress | jq .
```

## Volume Management

### Understanding Volumes

The project uses Docker named volumes with local driver and bind mounts:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/kharuya/data/mariadb
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/kharuya/data/wordpress
```

### Volume Operations

```bash
# List all volumes
docker volume ls

# Inspect volume
docker volume inspect mariadb_data

# Check data on host
ls -la /home/kharuya/data/mariadb/
ls -la /home/kharuya/data/wordpress/

# Backup volumes
tar -czf wordpress_backup.tar.gz /home/kharuya/data/wordpress/
tar -czf mariadb_backup.tar.gz /home/kharuya/data/mariadb/

# Restore volumes
tar -xzf wordpress_backup.tar.gz -C /home/kharuya/data/
```

### Persistent Data Locations

**WordPress files:**
```
/home/kharuya/data/wordpress/
├── wp-admin/          # WordPress core admin
├── wp-content/        # Themes, plugins, uploads
├── wp-includes/       # WordPress core files
├── wp-config.php      # WordPress configuration
└── index.php          # Entry point
```

**MariaDB data:**
```
/home/kharuya/data/mariadb/
├── inception_db/      # WordPress database
├── ibdata1           # InnoDB data file
└── ib_logfile*       # InnoDB logs
```

## Network Configuration

### Docker Network

Project uses a custom bridge network:

```bash
# View network
docker network inspect inception_network

# Network structure
docker network ls
```

### Inter-container Communication

Services use DNS names for communication:
- WordPress → MariaDB: `mariadb:3306`
- NGINX → WordPress: `wordpress:9000`
- All containers: `inception_network`

### External Access

Only NGINX port 443 is exposed:
```yaml
ports:
  - "443:443"  # Host:Container
```

### Dependency Management

```yaml
depends_on:
  wordpress:
    condition: service_started
  mariadb:
    condition: service_started
```

This ensures startup order but doesn't wait for service readiness (handled by entrypoint scripts).

## Configuration Files

### Makefile

```makefile
# Key targets
make all      # Setup + build + start
make up       # Build and start
make down     # Stop
make restart  # Stop and start
make clean    # Stop and remove volumes
make fclean   # Complete cleanup
make rebuild  # Rebuild images
make help     # Show targets
```

### docker-compose.yml

Key sections:
- `services`: NGINX, WordPress, MariaDB definitions
- `volumes`: Named volume configurations
- `networks`: Custom bridge network

Changes require: `make rebuild` or `docker compose up --build`

### .env File

Source of truth for all configuration. Format:
```
KEY=value
MYSQL_DATABASE=inception_db
```

Changes require: Container restart or rebuild depending on timing

### nginx.conf

NGINX configuration in `srcs/requirements/nginx/conf/nginx.conf`:
- Server blocks
- SSL/TLS settings
- PHP-FPM upstream
- Location directives

Changes require: NGINX container rebuild

## Development Workflow

### Making Code Changes

#### Modifying NGINX Configuration

1. Edit `srcs/requirements/nginx/conf/nginx.conf`
2. Rebuild: `docker compose -f srcs/docker-compose.yml build nginx`
3. Restart: `docker compose -f srcs/docker-compose.yml up -d nginx`
4. Verify: `docker compose logs nginx`

#### Modifying PHP Configuration

1. Edit `srcs/requirements/wordpress/Dockerfile`
2. Rebuild: `make rebuild`
3. Restart: `make up`

#### Modifying Database Configuration

1. Edit `srcs/requirements/mariadb/Dockerfile` or `tools/entrypoint.sh`
2. **Warning:** Existing data may need manual migration
3. Backup first: `make clean` creates backup opportunity
4. Rebuild: `make rebuild`

### Testing Changes

```bash
# Test configuration syntax
docker exec nginx nginx -t

# Test database connection
docker exec wordpress mariadb -h mariadb -u kharuya -pPASSWORD -e "SELECT 1;"

# Test WordPress CLI
docker exec wordpress wp --allow-root wp version

# Test PHP
docker exec wordpress php -v
docker exec wordpress php -m
```

## Troubleshooting Development Issues

### Entrypoint Script Issues

```bash
# Check script execution
docker logs wordpress

# Test script manually
docker exec -it wordpress bash
cd /var/www/html
wp core is-installed --allow-root

# Debug script
docker exec wordpress bash -x /usr/local/bin/entrypoint.sh
```

### PHP-FPM Configuration

```bash
# Verify listening port
docker exec wordpress cat /etc/php/8.2/fpm/pool.d/www.conf | grep listen

# Test PHP-FPM socket/port
docker exec wordpress netstat -ln | grep 9000

# View PHP info
docker exec wordpress php -i
```

### MariaDB Configuration

```bash
# Check bind address
docker exec mariadb cat /etc/mysql/mariadb.conf.d/50-server.cnf | grep bind

# Test connection from WordPress
docker exec wordpress mariadb -h mariadb -u kharuya -pPASSWORD -e "SHOW DATABASES;"

# Check user privileges
docker exec mariadb mariadb -u root -pPASSWORD -e "SHOW GRANTS FOR 'kharuya'@'%';"
```

### NGINX Connectivity

```bash
# Test NGINX configuration
docker exec nginx nginx -t

# Check listening ports
docker exec nginx netstat -ln | grep 443

# Test SSL certificate
docker exec nginx openssl x509 -in /etc/nginx/ssl/inception.crt -text -noout

# Test upstream connection
docker exec nginx curl http://wordpress:9000
```

## Database Management

### WordPress Database Operations

```bash
# Connect to database
docker exec -it mariadb mariadb -u root -p inception_db

# View tables
SHOW TABLES;

# Check WordPress users
SELECT * FROM wp_users;

# Check WordPress options
SELECT * FROM wp_options WHERE option_name IN ('siteurl', 'home');

# Export database
docker exec mariadb mysqldump -u root -pPASSWORD inception_db > backup.sql

# Import database
docker exec -i mariadb mysql -u root -pPASSWORD inception_db < backup.sql
```

### WordPress CLI Operations

```bash
# WordPress version
docker exec wordpress wp --allow-root core version

# Check installation
docker exec wordpress wp --allow-root core is-installed

# User management
docker exec wordpress wp --allow-root user list
docker exec wordpress wp --allow-root user get 1

# Install plugins
docker exec wordpress wp --allow-root plugin install akismet --activate

# Check WordPress health
docker exec wordpress wp --allow-root site health get
```

## Security Considerations

### Development vs Production

This setup is **for development only**:
- ❌ Self-signed certificates (not trusted by browsers)
- ❌ Default weak passwords (must be changed)
- ❌ Root database access with passwords
- ❌ No input validation on endpoints
- ❌ Debug logging enabled

### Production Checklist

For production deployment:
- ✅ Use valid SSL certificates (Let's Encrypt)
- ✅ Strong, unique passwords for all accounts
- ✅ Database user with limited privileges
- ✅ Environment variables from secrets manager
- ✅ Disable debug logging
- ✅ Implement rate limiting
- ✅ Add WAF (Web Application Firewall)
- ✅ Regular backups and testing
- ✅ Security monitoring and alerting

### Credential Management

**Current approach (development):**
```bash
# .env file (must be in .gitignore)
MYSQL_PASSWORD=password123
```

**Better approach (production):**
```bash
# Docker Secrets
echo "password123" | docker secret create db_password -

# Environment from external service
docker run --secret db_password \
  -e MYSQL_PASSWORD_FILE=/run/secrets/db_password
```

## Performance Optimization

### Resource Limits

Add to docker-compose.yml if needed:
```yaml
services:
  wordpress:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### Database Optimization

```sql
-- Add indexes
ALTER TABLE wp_posts ADD INDEX post_type_date (post_type, post_date);

-- Check slow queries
SHOW FULL PROCESSLIST;

-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
```

### PHP-FPM Tuning

In Dockerfile:
```bash
RUN sed -i 's/pm.max_children = 5/pm.max_children = 20/g' /etc/php/8.2/fpm/pool.d/www.conf
RUN sed -i 's/pm.start_servers = 2/pm.start_servers = 5/g' /etc/php/8.2/fpm/pool.d/www.conf
```

### NGINX Optimization

In nginx.conf:
```nginx
# Caching
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;
proxy_cache my_cache;

# Compression
gzip on;
gzip_types text/plain text/css application/json;
```

## Common Development Tasks

### Adding WordPress Plugins

```bash
docker exec wordpress wp --allow-root plugin install plugin-name --activate
```

### Changing WordPress Theme

```bash
docker exec wordpress wp --allow-root theme activate theme-name
```

### Running Database Migrations

```bash
docker exec wordpress wp --allow-root db query < migration.sql
```

### Clearing Caches

```bash
# WordPress cache
docker exec wordpress rm -rf /var/www/html/wp-content/cache/*

# NGINX cache
docker exec nginx rm -rf /var/cache/nginx/*

# Browser cache (client-side)
# Requires manual browser cache clear
```

### Debugging WordPress

Enable debug in `wp-config.php`:
```bash
docker exec wordpress wp --allow-root config set WP_DEBUG true
docker exec wordpress wp --allow-root config set WP_DEBUG_LOG true
docker exec wordpress wp --allow-root config set WP_DEBUG_DISPLAY false
```

View debug log:
```bash
docker exec wordpress tail -f /var/www/html/wp-content/debug.log
```

## CI/CD Integration

### Health Check Script

```bash
#!/bin/bash
# health_check.sh

# Check containers
docker compose -f srcs/docker-compose.yml ps | grep -q "Up"

# Check HTTPS
curl -k https://kharuya.42.fr/ > /dev/null 2>&1

# Check database
docker exec wordpress mariadb -h mariadb -u kharuya -p${MYSQL_PASSWORD} -e "SELECT 1;" > /dev/null 2>&1

echo "All systems operational"
```

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB Server Documentation](https://mariadb.com/kb/en/mariadb-server-documentation/)
- [WordPress Developer Documentation](https://developer.wordpress.org/)
- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/)
