FROM debian:buster

# Update package list and install deps
RUN apt-get update && apt-get install -y \
  curl \
  jq \
  postgresql-client \
  netcat \
  docker.io \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the entrypoint.sh script
COPY ./entrypoint.sh /app/entrypoint.sh

# Set the entrypoint.sh script as executable
RUN chmod +x /app/entrypoint.sh

# Run entrypoint.sh script
ENTRYPOINT ["app/entrypoint.sh"]
