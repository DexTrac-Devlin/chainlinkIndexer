#!/bin/sh

# Load environment variables from .env file
set -o allexport
source /app/.env
set +o allexport

# Chainlink Nodes Variables
API_USERNAME="$API_USERNAME"
API_PASSWORD="$API_PASSWORD"

# PostgreSQL Variables
POSTGRES_TIMEOUT_SECONDS=3
POSTGRES_HOST="$POSTGRES_HOST"
POSTGRES_PORT="$POSTGRES_PORT"
POSTGRES_DB="$POSTGRES_DB"
POSTGRES_USER="$POSTGRES_USER"
POSTGRES_PASSWORD="$POSTGRES_PASSWORD"
POSTGRES_TABLE='chainlink_bridges'

# Test PostgreSQL connection with provided vars
if timeout 1 bash -c "echo >/dev/tcp/$POSTGRES_HOST/$POSTGRES_PORT"; then
    echo "PostgreSQL is listening on port 5432. Proceeding with further commands."
    # Add your commands here
else
    echo "Unable to connect to PostgreSQL at $POSTGRES_HOST:$POSTGRES_PORT. Aborting."
    exit 1
fi

# Check if the database exists, and create it if not
PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="postgres" <<-EOSQL
  SELECT 'CREATE DATABASE ${POSTGRES_DB}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_DB}')\gexec
EOSQL

# Create table if one does not already exist
PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="${POSTGRES_DB}" <<EOSQL
CREATE TABLE IF NOT EXISTS $POSTGRES_TABLE (
  id SERIAL PRIMARY KEY,
  node_url VARCHAR(255) NOT NULL,
  bridge_name VARCHAR(255) NOT NULL,
  bridge_url VARCHAR(255) NOT NULL,
  UNIQUE (node_url, bridge_name)
);
EOSQL

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
MAX_ATTEMPTS=20
COUNTER=0
while ! PGPASSWORD=${POSTGRES_PASSWORD} psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT 1" >/dev/null 2>&1; do
  COUNTER=$((COUNTER+1))
  if [ $COUNTER -ge $MAX_ATTEMPTS ]; then
    echo "PostgreSQL is unavailable after $MAX_ATTEMPTS attempts. Exiting."
    exit 1
  fi
  echo "PostgreSQL is unavailable. Retrying in 3 seconds... (Attempt: $COUNTER)"
  sleep 3
done
echo "PostgreSQL is ready."

# Fetch running containers and identify which ones are Chainlink nodes
for CONTAINER in $(docker ps --quiet --filter "status=running"); do
  if docker exec "$CONTAINER" sh -c 'command -v chainlink > /dev/null'; then

    # Get container(s)' IP address(es)
    CHAINLINK_URL=$(docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' "$CONTAINER"):6689

    # Define BRIDGE_TYPES_URL
    BRIDGE_TYPES_URL=https://${CHAINLINK_URL}/v2/bridge_types

    # Get an auth cookiefile
    curl -k -s -c cookiefile -X POST -H 'Content-Type: application/json' -d "{\"email\":\"$API_USERNAME\", \"password\":\"$API_PASSWORD\"}" https://${CHAINLINK_URL}/sessions

    # Query the endpoint to extract the bridge name and associated URL
    BRIDGE_NAMES=$(curl -c cookiefile -b cookiefile --insecure --silent --show-error $BRIDGE_TYPES_URL | jq -r '.data[] | .attributes.name')
    BRIDGE_URLS=$(curl -c cookiefile -b cookiefile --insecure --silent --show-error $BRIDGE_TYPES_URL | jq -r '.data[] | .attributes.url')

    # Update chainlink_bridges table with bridge names and bridge urls
    BRIDGE_DATA=$(paste <(echo "$BRIDGE_NAMES") <(echo "$BRIDGE_URLS") -d ' ')
    while read -r BRIDGE_NAME BRIDGE_URL; do
      PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="${POSTGRES_DB}" <<EOSQL
INSERT INTO ${POSTGRES_TABLE} (node_url, bridge_name, bridge_url) VALUES ('${CHAINLINK_URL}', '${BRIDGE_NAME}', '${BRIDGE_URL}')
ON CONFLICT (node_url, bridge_name) DO UPDATE SET bridge_url = EXCLUDED.bridge_url;
EOSQL
    done <<< "$BRIDGE_DATA"

  fi
done

# Print results
echo "Chainlink bridges:"
PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="${POSTGRES_DB}" --command "SELECT * FROM chainlink_bridges;"
