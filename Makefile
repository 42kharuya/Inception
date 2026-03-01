.PHONY: all up down restart clean help data-dir

# Variables
USERNAME := $(shell whoami)
DATA_DIR := /home/$(USERNAME)/data
DOCKER_COMPOSE := cd srcs && docker compose
DOCKER_COMPOSE_CMD := docker compose -f srcs/docker-compose.yml

# Default target (up already depends on data-dir, so dependencies are automatically resolved)
all: up

# Create data directories for volumes
data-dir:
	@echo "Creating data directories at $(DATA_DIR)..."
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@sudo chmod 755 $(DATA_DIR)/mariadb
	@sudo chmod 755 $(DATA_DIR)/wordpress
	@echo "Data directories created successfully!"

# Build and start all containers
up: data-dir
	@echo "Building and starting containers..."
	@$(DOCKER_COMPOSE_CMD) up -d --build
	@echo "Containers started successfully!"

# Stop all containers
down:
	@echo "Stopping containers..."
	@$(DOCKER_COMPOSE_CMD) down
	@echo "Containers stopped!"

# Restart all containers
restart: down up

# Remove containers and volumes (down -v includes stopping containers)
clean:
	@echo "Cleaning up containers and volumes..."
	@$(DOCKER_COMPOSE_CMD) down -v
	@echo "Cleaning complete!"

# Remove everything including data directories
fclean: clean
	@echo "Removing all data..."
	@sudo rm -rf $(DATA_DIR)
	@echo "All data removed!"

# Rebuild containers
rebuild: down
	@echo "Rebuilding containers..."
	@$(DOCKER_COMPOSE_CMD) build --no-cache
	@echo "Build complete! Run 'make up' to start containers."

# Display help
help:
	@echo "Available targets:"
	@echo "  make all       - Create data dirs, build and start containers"
	@echo "  make up        - Build and start containers"
	@echo "  make down      - Stop containers"
	@echo "  make restart   - Restart containers (down then up)"
	@echo "  make clean     - Stop containers and remove volumes"
	@echo "  make fclean    - Complete cleanup including data directories"
	@echo "  make rebuild   - Rebuild all images"
	@echo "  make help      - Display this help message"