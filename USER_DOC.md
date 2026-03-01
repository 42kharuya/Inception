# User Documentation - Inception Project

## Overview

Welcome to the Inception infrastructure! This documentation explains how to use the deployed WordPress website and manage the services that power it.

## Understanding the Services

### What services are running?

The Inception stack consists of three main services:

1. **NGINX Web Server** (inception_network:443)
   - Handles all HTTPS connections
   - Reverse proxy to WordPress (PHP-FPM)
   - Serves static files (CSS, JavaScript, images)
   - Only accessible via HTTPS on port 443

2. **WordPress + PHP-FPM** (inception_network:9000)
   - Web application and content management system
   - PHP execution runtime
   - Not directly exposed to the internet
   - Only accessible through NGINX

3. **MariaDB Database** (inception_network:3306)
   - Stores all WordPress data (posts, users, settings)
   - User accounts and authentication
   - Not accessible from outside containers
   - Automatically started with the stack

### Data Storage

Two named volumes store persistent data:

- **wordpress_data**: WordPress website files, themes, plugins, uploads
  - Location: `/home/kharuya/data/wordpress`
  - Used by: WordPress container and NGINX

- **mariadb_data**: MySQL database files
  - Location: `/home/kharuya/data/mariadb`
  - Used by: MariaDB container

**Important:** If you delete these volumes, all website data and database records will be lost!

## Initial Setup (Critical Step)

### ⚠️ Before Starting for the First Time

The project requires secret credential files that are **NOT** stored in git for security reasons. You must create these files manually before running the containers.

**Required Files to Create:**

```bash
# Navigate to the project root
cd /path/to/Inception

# Create the secrets directory
mkdir -p secrets/

# Create database root password file
echo "your_secure_root_password" > secrets/db_root_password.txt

# Create database user password file
echo "your_secure_db_password" > secrets/db_password.txt

# Create WordPress credentials file
cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_PASSWORD=your_admin_password
WP_USER_PASSWORD=your_user_password
EOF

# Set secure file permissions
chmod 600 secrets/*.txt
```

**File Contents Explained:**
- **db_root_password.txt**: MariaDB root user password (one line, no variable name)
- **db_password.txt**: MariaDB user password for 'kharuya' (one line, no variable name)
- **credentials.txt**: WordPress passwords (two lines with KEY=value format)

**Secure Password Examples:**
```bash
# Option 1: Using openssl to generate strong passwords
openssl rand -base64 32 > secrets/db_root_password.txt
openssl rand -base64 32 > secrets/db_password.txt

# Option 2: Manual creation
echo "MySecurePass@123!456#789" > secrets/db_root_password.txt
echo "DBUser@Pass#2024!Secure" > secrets/db_password.txt

cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_PASSWORD=AdminPass@123!Secure456
WP_USER_PASSWORD=UserPass#2024!Secure789
EOF
```

**Important Reminders:**
- ✅ These files are in `.gitignore` - they will NEVER be committed to git
- ✅ Create unique passwords for each environment
- ✅ Use strong passwords (16+ characters with mixed case, numbers, symbols)
- ⚠️ Keep your credentials somewhere safe - if lost, you'll need database recovery

Once these files are created, proceed to starting the infrastructure.

## Starting and Stopping the Stack

### Starting the Infrastructure

```bash
# From the Inception directory
make all
```

This command will:
1. Create necessary data directories
2. Build all container images
3. Start all containers
4. Display initialization logs

Wait 10-20 seconds for all services to be fully ready (MariaDB initialization takes time).

### Stopping the Infrastructure

```bash
make down
```

This command will:
- Stop all running containers gracefully
- Keep all data (volumes preserved)
- Containers can be restarted later with `make up`

### Restarting the Infrastructure

```bash
make restart
```

Equivalent to:
```bash
make down && make up
```

### Checking Service Status

```bash
# View running containers
docker compose -f srcs/docker-compose.yml ps

# View container logs
docker compose -f srcs/docker-compose.yml logs -f

# View logs for specific service
docker compose -f srcs/docker-compose.yml logs wordpress
```

## Accessing the Website and Admin Panel

### Prerequisites

Add the domain to your hosts file:

**Linux/macOS:**
```bash
sudo echo "127.0.0.1 kharuya.42.fr" >> /etc/hosts
```

**Windows:**
Add this line to `C:\Windows\System32\drivers\etc\hosts`:
```
127.0.0.1 kharuya.42.fr
```

### Accessing WordPress

**Website:** https://kharuya.42.fr

You'll see a security warning about the self-signed certificate. This is normal for development - click "Advanced" and "Proceed" or accept the certificate exception.

### WordPress Admin Panel

**URL:** https://kharuya.42.fr/wp-admin

**Login:**
- **Admin Username:** 42tokyo_boss
- **Admin Password:** Check `.env` file (variable: `WP_ADMIN_PASSWORD`)

### Regular User Account

A regular author account is also available:
- **Username:** kharuya
- **Password:** Check `.env` file (variable: `WP_USER_PASSWORD`)
- **Role:** Author (can create posts but not manage plugins/themes)

## Credentials and Configuration

All credentials are stored in `srcs/.env` file:

```bash
# MariaDB
MYSQL_DATABASE=inception_db
MYSQL_USER=kharuya
MYSQL_PASSWORD=<your-password>
MYSQL_ROOT_PASSWORD=<your-root-password>

# WordPress
WP_ADMIN_USER=42tokyo_boss
WP_ADMIN_PASSWORD=<your-admin-password>
WP_ADMIN_EMAIL=your-email@example.com

WP_USER=kharuya
WP_USER_PASSWORD=<your-user-password>
WP_USER_EMAIL=your-email@example.com
```

**SECURITY WARNING:**
- Never commit `.env` to version control
- Never share credentials publicly
- Keep passwords secure and unique
- Change default passwords after initial setup

## Verifying Services Are Working

### Check Container Status

```bash
docker compose -f srcs/docker-compose.yml ps
```

Expected output (all UP):
```
NAME         IMAGE              COMMAND                  STATUS
mariadb      inception-mariadb  "/usr/local/bin/entr…"   Up 2 minutes
wordpress    inception-wordpress "/usr/local/bin/entr…"  Up 2 minutes
nginx        inception-nginx    "nginx -g daemon off…"   Up 2 minutes
```

### Check NGINX Connection

```bash
# Test HTTPS connection (ignore self-signed cert warning)
curl -k https://kharuya.42.fr/
```

Expected: HTML content of WordPress homepage

### Check Database Connection

From WordPress container:
```bash
docker exec wordpress mariadb -h mariadb -u kharuya -p${MYSQL_PASSWORD} -e "SELECT VERSION();"
```

Expected: MariaDB version number

### Check Logs for Errors

```bash
# View all logs
docker compose -f srcs/docker-compose.yml logs

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f

# View specific service logs
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

## Troubleshooting

### "Connection refused" when accessing https://kharuya.42.fr

**Solutions:**
1. Verify NGINX container is running: `docker compose ps`
2. Check if port 443 is accessible: `nc -zv localhost 443`
3. Wait longer (MariaDB initialization can take 30+ seconds)
4. Check NGINX logs: `docker compose logs nginx`
5. Restart the stack: `make restart`

### "Cannot connect to database" error in WordPress

**Solutions:**
1. Verify MariaDB is running: `docker compose logs mariadb`
2. Check database initialization completed: Look for "WordPress setup completed!" in logs
3. Verify database credentials in `.env` match WordPress config
4. Restart MariaDB: `docker compose restart mariadb`
5. Complete restart: `make restart`

### WordPress shows "ERR_SSL_PROTOCOL_ERROR"

**This is expected behavior!**
- The certificate is self-signed for development
- Click "Advanced" → "Proceed anyway" or accept the certificate exception
- This is not a problem with the infrastructure

### "Unable to login" to WordPress

**Solutions:**
1. Verify credentials in `.env` file
2. Check WordPress user exists: `docker exec wordpress wp user list --allow-root`
3. Reset admin password: `docker exec wordpress wp user update admin --prompt=user_pass --allow-root`
4. Clear WordPress cache if using cache plugin

### Data disappeared after restart

**This means volumes were deleted!**
1. Check if data directories exist: `ls -la /home/kharuya/data/`
2. If missing: `make fclean` then `make all` to rebuild
3. Note: Using `docker system prune` or `docker volume rm` deletes data

## Common Tasks

### Change WordPress Admin Password

```bash
docker exec wordpress wp user update admin --prompt=user_pass --allow-root
```

### Create New WordPress User

```bash
docker exec wordpress wp user create newuser newuser@example.com \
  --user_pass=password \
  --role=editor \
  --allow-root
```

### Backup Website Files

```bash
tar -czf wordpress_backup.tar.gz /home/kharuya/data/wordpress/
```

### Backup Database

```bash
docker exec mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD inception_db > db_backup.sql
```

### Clear WordPress Cache

```bash
docker exec wordpress rm -rf /var/www/html/wp-content/cache/*
```

### View WordPress Debug Logs

```bash
docker exec wordpress tail -f /var/www/html/wp-content/debug.log
```

## Accessing Containers

If you need to troubleshoot inside a container:

```bash
# Access WordPress container
docker exec -it wordpress bash

# Access MariaDB container
docker exec -it mariadb bash

# Access NGINX container
docker exec -it nginx bash
```

## Performance & Resource Usage

Check resource consumption:

```bash
docker stats
```

Expected values:
- MariaDB: 50-200 MB memory
- WordPress: 30-100 MB memory
- NGINX: 10-30 MB memory

If usage is significantly higher, check:
1. WordPress plugins (some are memory-hungry)
2. Database query logs for slow queries
3. Web server logs for error loops

## Network & Connectivity

### Container Network

Services communicate using Docker's internal DNS:
- nginx connects to wordpress:9000
- wordpress connects to mariadb:3306
- All containers on `inception_network` bridge

### Port Mapping

- **443 (HTTPS)** → External: Mapped from NGINX container
- **9000 (PHP-FPM)** → Internal only: WordPress to NGINX communication
- **3306 (MySQL)** → Internal only: WordPress to MariaDB communication

No ports are exposed except 443 (HTTPS).

## When to Restart Services

You should restart when:
- Making changes to `.env` environment variables
- Updating WordPress plugins/themes
- Changing NGINX configuration
- Database connection issues

**Restart command:**
```bash
make restart
```

## Important Security Notes

⚠️ **For Development Only**
- Self-signed SSL certificate (browser warnings are expected)
- Default passwords must be changed before production
- Database root account has password access from containers
- All credentials in plain text in `.env` file

⚠️ **Never**
- Commit `.env` to git
- Expose port 3306 externally
- Use in production without proper hardening
- Share database root password
- Enable debug logging in production

## Getting Help

If something isn't working:

1. **Check logs:** `docker compose logs -f`
2. **Verify containers:** `docker compose ps`
3. **Check volumes:** `docker volume ls`
4. **Review configuration:** `cat srcs/.env`
5. **Reset everything:** `make fclean && make all`

For more technical details, see [DEV_DOC.md](DEV_DOC.md).
