FROM alpine:latest

RUN apk add --no-cache curl jq postgresql-client telnet

COPY entrypoint.sh /
COPY init.sql /

ENV POSTGRES_HOST=localhost
ENV POSTGRES_PORT=5432
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password
ENV POSTGRES_DB=chainlink_bridges

ENTRYPOINT ["/entrypoint.sh"]
