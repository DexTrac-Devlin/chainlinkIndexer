FROM alpine:3.14

RUN apk add --no-cache curl jq postgresql-client busybox-extras coreutils

COPY entrypoint.sh /

ENV POSTGRES_HOST=localhost
ENV POSTGRES_PORT=5432
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password
ENV POSTGRES_DB=chainlink_bridges

ENTRYPOINT ["/entrypoint.sh"]
