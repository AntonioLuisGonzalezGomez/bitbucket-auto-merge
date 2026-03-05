FROM alpine:3.18

RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates \
    libc6-compat \
    openssl \
    coreutils

RUN update-ca-certificates

WORKDIR /app
RUN mkdir -p /app/output
VOLUME ["/app/output"]

COPY bb-tool.sh /app/bb-tool.sh
RUN chmod +x /app/bb-tool.sh

ENTRYPOINT ["/app/bb-tool.sh"]