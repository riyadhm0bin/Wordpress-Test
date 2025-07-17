# Makefile for WordPress + MySQL + phpMyAdmin project

# Define variables
TIMESTAMP=$(shell date +%F_%H-%M-%S)
BACKUP_DIR=./mysql-backups/$(TIMESTAMP)
BACKUP_FILE=$(BACKUP_DIR)/queryopt_db_backup.sql
CONTAINER_NAME=mysql
DB_USER=queryopt
DB_PASSWORD=queryopt_password
DB_NAME=queryopt_db

# Backup the MySQL database from Docker container
dbbackup-old:
	@echo "Creating backup directory: $(BACKUP_DIR)"
	@mkdir -p $(BACKUP_DIR)
	@echo "Running mysqldump from container: $(CONTAINER_NAME)"
	@docker exec $(CONTAINER_NAME) /usr/bin/mysqldump -u $(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) > $(BACKUP_FILE)
	@echo "Backup saved to $(BACKUP_FILE)"

# Backup the MySQL database and compress it with gzip
dbbackup:
	@echo "Creating backup directory: $(BACKUP_DIR)"
	@mkdir -p $(BACKUP_DIR)
	@echo "Running mysqldump from container: $(CONTAINER_NAME) and compressing"
	@docker exec $(CONTAINER_NAME) /usr/bin/mysqldump -u $(DB_USER) -p$(DB_PASSWORD) $(DB_NAME) | gzip > $(BACKUP_FILE).gz
	@echo "Compressed backup saved to $(BACKUP_FILE).gz"

# Restore the MySQL database inside the container
# Usage: make dbrestore FILE=./mysql-backups/2025-05-20_10-00-00/queryopt_db_backup.sql
dbrestore-old:
ifndef FILE
	$(error Please provide a backup file to restore using: make dbrestore FILE=path/to/file.sql)
endif
	@echo "Restoring database '$(DB_NAME)' from host file $(FILE)"
	@cat $(FILE) | docker exec -i $(CONTAINER_NAME) /usr/bin/mysql -u $(DB_USER) -p$(DB_PASSWORD) $(DB_NAME)
	@echo "Database restored from $(FILE)"


dbrestore:
ifndef FILE
	$(error Please provide a backup file to restore using: make dbrestore FILE=path/to/file.sql or .sql.gz)
endif
	@echo "Restoring database '$(DB_NAME)' from host file $(FILE)"
	@if echo $(FILE) | grep -qE '\.gz$$'; then \
		gunzip -c $(FILE) | docker exec -i $(CONTAINER_NAME) /usr/bin/mysql -u $(DB_USER) -p$(DB_PASSWORD) $(DB_NAME); \
	else \
		cat $(FILE) | docker exec -i $(CONTAINER_NAME) /usr/bin/mysql -u $(DB_USER) -p$(DB_PASSWORD) $(DB_NAME); \
	fi
	@echo "Database restored from $(FILE)"
# Example Restore command: make dbrestore FILE=./mysql-backups/2025-05-20_12-38-18/queryopt_db_backup.sql


# Clean all but the latest 3 backups
clean:
	@echo "Cleaning all but the latest 3 backups"
	@ls -dt ./mysql-backups/* | tail -n +2 | xargs rm -rf || true
	@echo "Old backups cleaned, keeping the latest 3"

# Start the Docker containers
up:
	@echo "Starting Docker containers"
	@docker-compose up -d

# Stop the Docker containers
down:
	@echo "Stopping Docker containers"
	@docker-compose down

# List running Docker containers
ps:
	@echo "Listing running Docker containers"
	@docker ps

# Build Docker containers
build:
	@echo "Building Docker containers"
	@docker-compose build

# Setup environment (build + up)
setup:
	@echo "Setting up the environment"
	@make build
	@make up