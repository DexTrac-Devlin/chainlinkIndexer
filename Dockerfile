FROM debian:buster

# Update package list and install deps
RUN apt-get update && apt-get install -y \
  apt-utils \
  curl \
  docker.io --no-install-recommends \
  jq \
  netcat \
  postgresql-client && \
  rm -rf /var/lib/apt/lists/* && \
  useradd -ms /bin/bash indexer && \
  usermod -aG docker indexer

USER indexer

# Copy the entrypoint.sh script
COPY ./entrypoint.sh /entrypoint.sh

# Set the entrypoint.sh script as executable
RUN chmod +x /entrypoint.sh

# Run entrypoint.sh script
ENTRYPOINT ["/entrypoint.sh"]
