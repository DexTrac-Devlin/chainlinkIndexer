# Concord Agent

This repository contains a Concord Agent script and a TypeScript API for monitoring Chainlink nodes and their external adapters. The Concord Agent script collects data about Chainlink nodes an
d their bridges, storing the information in a PostgreSQL database. The TypeScript API serves the collected data from the PostgreSQL database.

## Directory Structure

```
chainlinkIndexer/
├── api
│   ├── Dockerfile
│   ├── package.json
│   ├── src
│   │   └── index.ts
│   └── tsconfig.json
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
├── init.sql
├── LICENSE
└── README.md

```

## Prerequisites

- Docker
- Docker Compose

## Installation

1. Clone the repository:


`git clone https://github.com/DexTrac-Devlin/chainlinkIndexer.git`


Change directory to the chainlinkIndexer folder:

`cd concordAgent`


Build the Docker containers for all services:

`docker-compose build`

Update the environment variables in the .env file according to your configuration:
```
# Chainlink Node(s) Details
API_USERNAME=name@domain.com
API_PASSWORD=chainlink_ui_password

# PostgreSQL Details
POSTGRES_TIMEOUT_SECONDS=3
POSTGRES_HOST=192.168.88.2
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=concord_agent
POSTGRES_TABLE=chainlink_bridges
```

Start the PostgreSQL, indexer, and API services:

`docker-compose up`

The Concord Agent will start running, and the TypeScript API will be accessible at http://localhost:3000/bridges.

API Endpoints
GET /bridges: Fetch the list of Chainlink bridges and their associated dat.a from the PostgreSQL database.
For any questions or issues, please open an issue on the repository.


This README was built with assistance from ChatGPT


This README provides an overview of the Chainlink indexer project, instructions for installation, and information about the API endpoints. You can add this README.md file to the root of the 
`chainlinkIndexer` repository.
