.PHONY: all up down restart clean help data-dir

# 変数
USERNAME := $(shell whoami)
DATA_DIR := /home/$(USERNAME)/data
DOCKER_COMPOSE_CMD := docker compose -f srcs/docker-compose.yml

# デフォルトターゲット
all: up

# ボリューム用のデータディレクトリを作成
data-dir:
	@echo "Creating data directories at $(DATA_DIR)..."
	@mkdir -m 755 -p $(DATA_DIR)/DB
	@mkdir -m 755 -p $(DATA_DIR)/WordPress
	@echo "Data directories created successfully!"

# コンテナをビルドして起動（--build：イメージをプルせずにビルドする）
up: data-dir
	@echo "Building and starting containers..."
	@$(DOCKER_COMPOSE_CMD) up -d --build
	@echo "Containers started successfully!"

# すべてのコンテナを停止
down:
	@echo "Stopping containers..."
	@$(DOCKER_COMPOSE_CMD) down
	@echo "Containers stopped!"

# コンテナを再起動（down → up）
restart: down up

# コンテナとボリュームを削除（down -v はコンテナ停止を含む）
clean:
	@echo "Cleaning up containers and volumes..."
	@$(DOCKER_COMPOSE_CMD) down -v
	@echo "Cleaning complete!"

# すべてを削除（データディレクトリも含む）
fclean: clean
	@echo "Removing all data..."
	@sudo rm -rf $(DATA_DIR)
	@echo "All data removed!"

# コンテナを再ビルド
rebuild: down
	@echo "Rebuilding containers..."
	@$(DOCKER_COMPOSE_CMD) build --no-cache
	@echo "Build complete! Run 'make up' to start containers."

# ヘルプを表示
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