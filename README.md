# Inception

*This project has been created as part of the 42 curriculum by kharuya.*

## Description

Inception is a Docker infrastructure project that sets up a complete web stack using containerization. The project demonstrates system administration skills by configuring multiple services (NGINX, WordPress, and MariaDB) to work together in isolated containers.

### What is this project?

This project creates a small but complete infrastructure using Docker and Docker Compose. Instead of running applications on a single machine, each service runs in its own container:

- **NGINX**: Reverse proxy and web server handling HTTPS connections
- **WordPress + PHP-FPM**: Web application and PHP runtime
- **MariaDB**: Database backend for WordPress
- **Named Volumes**: Persistent data storage for database and website files
- **Docker Network**: Internal communication between containers

### Key Features

- 🔒 TLS/SSL encryption (TLSv1.2 and TLSv1.3 only)
- 📦 Multi-container architecture with named volumes
- 🔄 Automatic container restart on failure
- 🌐 Custom domain name routing (kharuya.42.fr)
- 🛡️ Environment-based configuration with secrets
- 📝 Proper process management (PID 1) in containers

## Instructions

### Prerequisites

- Linux-based system (VM recommended)
- Docker and Docker Compose installed
- Make utility
- User account (default: kharuya, adjust paths as needed)

### Building and Running

**Quick Start:**

```bash
# Clone the repository
git clone <repo-url>
cd Inception

# Start the infrastructure
make all
```

**Available Make Targets:**

```bash
make all         # Create data directories, build and start containers
make up          # Build and start containers
make down        # Stop containers
make restart     # Restart all containers
make clean       # Stop containers and remove volumes
make fclean      # Complete cleanup including data
make rebuild     # Rebuild all images
make help        # Display help message
```

### Accessing the Services

After running `make all`:

1. **WordPress**: https://kharuya.42.fr
   - Admin Panel: https://kharuya.42.fr/wp-admin
   - Admin User: 42tokyo_boss (see `.env` for password)

2. **Database**: Internal only (accessible from WordPress/PHP containers)

**Note:** You may need to add `kharuya.42.fr` to your `/etc/hosts` file:
```bash
sudo echo "127.0.0.1 kharuya.42.fr" >> /etc/hosts
```

### Configuration

The project uses environment variables stored in `srcs/.env`. Key variables:

```bash
DOMAIN_NAME=kharuya.42.fr
MYSQL_DATABASE=inception_db
MYSQL_USER=kharuya
MYSQL_PASSWORD=<password>
MYSQL_ROOT_PASSWORD=<root-password>
WP_ADMIN_USER=42tokyo_boss
WP_ADMIN_PASSWORD=<admin-password>
```

**Security Note:** Credentials should never be committed to git. Use `.gitignore` to exclude:
- `secrets/` directory
- `srcs/.env` (or keep it in a secure location)

### Project Structure

```
Inception/
├── Makefile                          # Automation script
├── README.md                         # This file
├── USER_DOC.md                       # User documentation
├── DEV_DOC.md                        # Developer documentation
├── secrets/                          # Credentials directory
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                          # Environment variables
    ├── docker-compose.yml            # Container orchestration
    └── requirements/
        ├── nginx/                    # Web server
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/
        ├── wordpress/                # Web application
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/entrypoint.sh
        ├── mariadb/                  # Database
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/entrypoint.sh
        └── bonus/                    # Additional services
```

## Technical Concepts Explained

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|------------------|-------------------|
| **Overhead** | Heavy (GB range) | Lightweight (MB range) |
| **Startup Time** | Minutes | Seconds |
| **Resource Efficiency** | Low - full OS per VM | High - shared kernel |
| **Isolation** | Complete isolation | Process-level isolation |
| **Use Case** | Multiple OS environments | Microservices, deployment |

**In Inception:** Docker containers provide lightweight isolation without VM overhead.

### Secrets vs Environment Variables

| Feature | Environment Variables | Docker Secrets |
|---------|----------------------|-----------------|
| **Visibility** | Visible in process environment | Mounted as files |
| **Rotation** | Manual process | Orchestrator-managed |
| **Access Control** | Limited | Fine-grained |
| **Persistence** | In .env files | External secret store |
| **Ideal For** | Configuration | Sensitive credentials |

**In Inception:** We use both - `.env` for configuration, secrets directory for credentials (should be stored separately in production).

### Docker Network vs Host Network

| Aspect | Docker Network | Host Network |
|--------|----------------|--------------|
| **Isolation** | Full network isolation | None - uses host network |
| **Port Mapping** | Required (443:443) | Not needed |
| **Container Communication** | Service name DNS resolution | localhost:port |
| **Security** | Better (isolated) | Worse (exposed) |
| **Performance** | Slight overhead | Minimal overhead |

**In Inception:** Custom bridge network (`inception_network`) provides isolation between containers while allowing inter-container communication via service names.

### Docker Volumes vs Bind Mounts

| Feature | Named Volumes | Bind Mounts |
|---------|---------------|------------|
| **Management** | Docker-managed | Host-managed |
| **Location** | Docker area | Anywhere on host |
| **Permissions** | Docker handles | User-managed |
| **Performance** | Better on macOS/Windows | Varies |
| **Portability** | More portable | Less portable |
| **Use Case** | Database storage | Source code development |

**In Inception:** Named volumes ensure proper permission management and data persistence for WordPress files and database.

## Resources and References

### Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress.org](https://wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

### Tutorials & Articles

- Docker Best Practices
- Container Networking Fundamentals
- TLS/SSL Certificate Configuration
- WordPress Deployment with Docker

### AI Usage in This Project

AI assistance was used in the following areas:

1. **Configuration Templates**: NGINX configuration, Docker networking setup
2. **Scripting**: Entrypoint scripts for proper process management (PID 1)
3. **Documentation**: Structure and content of configuration comparisons
4. **Troubleshooting**: Debug strategies for container startup and networking issues
5. **Code Review**: Validation of best practices for Dockerfile and docker-compose.yml

**Critical Components Reviewed Manually:**
- All security configurations (TLS, database privileges)
- Volume mounts and data persistence
- Environment variable handling and secrets management
- Container networking and communication
- Dockerfile instructions and best practices

## Troubleshooting

### Containers won't start

```bash
# Check logs
docker compose -f srcs/docker-compose.yml logs -f

# Verify images were built
docker images | grep inception

# Reset everything
make fclean
make all
```

### Database connection errors

```bash
# Verify MariaDB is running
docker compose -f srcs/docker-compose.yml ps

# Check environment variables
docker exec wordpress env | grep MYSQL
```

### Volume issues

```bash
# Check volume status
docker volume ls
docker volume inspect mariadb_data

# Verify data directory permissions
ls -la /home/kharuya/data/
```

## Notes

- The project must run on a Linux VM
- All images are built from Debian/Alpine base images (not pre-built)
- Container restarts are automatic via `restart: always` policy
- TLS certificates are self-signed (suitable for development)
- Passwords and sensitive data must be kept in `.env` and excluded from git

## License

This is an educational project created for the 42 curriculum.