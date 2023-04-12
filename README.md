# Concord Agent

Concord Agent is a utility for monitoring Chainlink nodes and updating a PostgreSQL table with bridge information.

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Uninstall + Cleanup](#Uninstall)
- [License](#license)

## Requirements
- Docker
- Docker Compose
- PostgreSQL

## Installation

1. Clone the repository:

`git clone https://github.com/DexTrac-Devlin/concordAgent.git`

`cd concordAgent`


2. Copy `.env.example` to `.env` and update the environment variables as needed:

`cp .env.example .env`

`nano .env`


3. Run the installation script:

`sudo bash install.sh`


The script will install the necessary dependencies, deploy the containers, and create a systemd service to run the Concord Indexer periodically.

## Usage

1. The Concord Indexer will be automatically run by the created systemd service every 15 minutes. You can check the status of the service with:

`sudo systemctl status concord_indexer`


2. If you need to manually run the Concord Indexer, execute the script:

`sudo -u concordIndexer /opt/concordAgent/concordIndexer.sh`


3. To view the information stored in the PostgreSQL table, run:

`PGPASSWORD=<your_postgres_password> psql --host=<postgres_host> --port=<postgres_port> --username=<postgres_user> --dbname=<postgres_db> --command "SELECT * FROM chainlink_bridges;"`


Replace `<your_postgres_password>`, `<postgres_host>`, `<postgres_port>`, `<postgres_user>`, and `<postgres_db>` with the appropriate values from your `.env` file.

4. To query the API service, run:
5. 
`curl http://localhost:3000/bridges | jq -r`

## Uninstall
1. Run the uninstall script:

`sudo bash uninstall.sh`


The script will bring down the PostgreSQL and API containers, delete the images, stop the concord_indexer service and delete the systemd file.



## License

[GPLv3](LICENSE)
