#!/bin/bash

# Load environment variables from .env
set -a
source .env
set +a

# Start the Docker containers
docker-compose down
docker-compose build
docker-compose up
