FROM debian:buster

# Update package list and install deps
RUN apt-get update && apt-get install -y \
    apt-utils \
    curl \
    docker.io \
    jq \
    netcat \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Add a new user and group called 'indexer'
RUN if ! getent group indexer; then groupadd -r indexer; fi && \
    if ! getent passwd indexer; then useradd -r -g indexer indexer; fi

# Set working directory
WORKDIR /

# Copy entrypoint.sh script
COPY entrypoint.sh /entrypoint.sh

# Set permissions on the entrypoint script
RUN chown indexer:indexer /entrypoint.sh

# Copy the .env file
COPY .env /.env

# Run the entrypoint script as 'indexer' user
USER indexer
CMD ["/entrypoint.sh"]
