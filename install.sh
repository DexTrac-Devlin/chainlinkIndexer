#!/bin/bash

# Formatting variables
# bold
b=$(tput bold)
# rm bold
ub=$(tput sgr0)
# underline
un=$(tput smul)
# rm underline
nun=$(tput rmul)
# black background
blk_bg=$(tput setab 0)
# blue foreground
blue_fg=$(tput setaf 6)
# yello foreground
yellow_fg=$(tput setaf 3)
# reset to default
reset=$(tput sgr0)

# Check if command is run with sudo, if not exit.
check_sudo() {
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run with sudo. Exiting."
  exit 1
fi
}


# Fetch/set the necessary variables
set_vars() {
WORKING_DIR=$(pwd)
source $WORKING_DIR/.env
}

# Install Docker and Docker Compose
install_deps() {
sudo apt-get update
sudo apt-get install -y \
  apt-utils \
  curl \
  docker.io \
  docker-compose \
  jq \
  netcat \
  postgresql-client \
  telnet
}

# Build and install necessary containers
deploy_containers() {
docker-compose build
docker-compose up -d
}

# Check connectivity to postgres with provided variables
check_postgres() {
echo "Waiting for PostgreSQL to be ready..."
MAX_ATTEMPTS=20 # 20 attempts; 3 sec between each attempt
COUNTER=0
while ! nc -z -w 5 "$POSTGRES_HOST" "$POSTGRES_PORT"; do
  sleep 1
  counter=$((counter + 1))
  if [ $counter -gt $MAX_ATTEMPTS ]; then
    echo "Unable to connect to PostgreSQL after 60 seconds. Exiting."
    exit 1
  fi
done
echo "PostgreSQL is ready."
echo ""
}

# Check if the database+table exists, and create it if not
init_postgres() {
PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="postgres" <<-EOSQL
  SELECT 'CREATE DATABASE ${POSTGRES_DB}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_DB}')\gexec
EOSQL

PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="${POSTGRES_DB}" <<EOSQL
CREATE TABLE IF NOT EXISTS $POSTGRES_TABLE (
  id SERIAL PRIMARY KEY,
  node_url VARCHAR(255) NOT NULL,
  bridge_name VARCHAR(255) NOT NULL,
  bridge_url VARCHAR(255) NOT NULL,
  UNIQUE (node_url, bridge_name)
);
EOSQL
}

# Check if concordIndexer user exists, if not create it
create_user() {
if ! id -u concordIndexer > /dev/null 2>&1; then
    sudo useradd -m concordIndexer
fi
# Check if the 'docker' group exists, if not create it
if ! getent group docker > /dev/null 2>&1; then
    sudo groupadd docker
fi
# add concordIndexer to docker group
sudo usermod -aG docker concordIndexer
}

# Create systemd service for concordAgent.sh that runs once every ~15 minutes
create_service() {
if [ ! -d /opt/concordAgent ]; then
  sudo mkdir /opt/concordAgent
fi
sudo cp $WORKING_DIR/concordIndexer.sh /opt/concordAgent/

sudo tee /etc/systemd/system/concord_indexer.service > /dev/null <<EOF
[Unit]
Description=Concord Indexer

[Service]
Type=simple
User=concordIndexer
ExecStart=/opt/concordAgent/concordIndexer.sh
Restart=always
RestartSec=900

[Install]
WantedBy=multi-user.target
EOF
}

# Reload systemd daemon and start service
start_concordIndexer() {
sudo systemctl daemon-reload
sudo systemctl enable concord_indexer
sudo systemctl start concord_indexer
}

# Print results
print_results(){
echo "The concordIndexer script is located at ${blue_fg}/opt/concordAgent/concordIndexer.sh${reset}"
echo "PostgreSQL Information:"
echo "  Database name: ${blue_fg}$POSTGRES_DB${reset}"
echo "  Table Name:    ${blue_fg}$POSTGRES_TABLE${reset}"
}

# Run
check_sudo
set_vars
install_deps
deploy_containers
check_postgres
init_postgres
create_user
create_service
start_concordIndexer
print_results
exit
