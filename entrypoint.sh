#!/bin/sh

# Chainlink Nodes Variables
API_USERNAME='name@domain.com'
API_PASSWORD='YOUR_PASSWORD'

# PostgreSQL Variables
POSTGRES_TIMEOUT_SECONDS=3
POSTGRES_HOST='POSTGRES_HOST_IP_OR_DNS'
POSTGRES_PORT='5432'
POSTGRES_DB='POSTGRES_DM_NAME'
POSTGRES_USER='POSTGRES_USERNAME'
POSTGRES_PASSWORD='POSTRGES_PASSWORD'
POSTGRES_TABLE='chainlink_bridges'

# Test connectivity to PostgreSQL host
if ! timeout $POSTGRES_TIMEOUT_SECONDS bash -c "</dev/tcp/${POSTGRES_HOST}/${POSTGRES_PORT}" >/dev/null 2>&1; then
  echo "Error: Connection to postgresql host at ${POSTGRES_HOST}:${POSTGRES_PORT} timed out"
  echo "Please check your settings."
  exit 1
fi

# Create database if one does not already exist
PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="${POSTGRES_DB}" <<-EOSQL
  CREATE TABLE IF NOT EXISTS $POSTGRES_TABLE (
    id SERIAL PRIMARY KEY,
    node_url VARCHAR(255) NOT NULL,
    bridge_name VARCHAR(255) NOT NULL,
    bridge_url VARCHAR(255) NOT NULL
  );
EOSQL

for CONTAINER in $(docker ps --quiet --filter "status=running"); do
  if docker exec "$CONTAINER" sh -c 'command -v chainlink > /dev/null'; then
    # Get container(s)' IP address(es)
    CHAINLINK_URL=$(docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' "$CONTAINER"):6689

    # Get an auth cookiefile
    curl -k -s -c cookiefile -X POST   -H 'Content-Type: application/json'   -d "{\"email\":\"$API_USERNAME\", \"password\":\"$API_PASSWORD\"}" https://${CHAINLINK_URL}/sessions

    # Query the endpoint to extract the bridge name and associated URL
    BRIDGE_NAMES=$(curl -c cookiefile -b cookiefile --insecure --silent --show-error $BRIDGE_TYPES_URL | jq -r '.data[] | .attributes.name')
    BRIDGE_URLS=$(curl -c cookiefile -b cookiefile --insecure --silent --show-error $BRIDGE_TYPES_URL | jq -r '.data[] | .attributes.url')

    # Update chainlink_bridges table with bridge names
    for BRIDGE_NAME in $BRIDGE_NAMES; do
      PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="${POSTGRES_DB}" <<-EOSQL
        INSERT INTO ${POSTGRES_TABLE} (node_url, bridge_name) VALUES ('${CHAINLINK_URL}', '${BRIDGE_NAME}');
      EOSQL
    done

    # Update chainlink_bridges table with bridge urls
    for BRIDGE_URL in $BRIDGE_URLS; do
      PGPASSWORD=${POSTGRES_PASSWORD} psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="${POSTGRES_DB}" <<-EOSQL
        INSERT INTO ${POSTGRES_TABLE} (node_url, bridge_url) VALUES ('${CHAINLINK_URL}', '${BRIDGE_URL}');
      EOSQL
    done

  fi
done

# Print results
echo "Chainlink bridges:"
psql --host="${POSTGRES_HOST}" --port="${POSTGRES_PORT}" --username="${POSTGRES_USER}" --dbname="${POSTGRES_DB}"
