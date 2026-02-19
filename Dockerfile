# Lightweight Docker image for Bitbucket Auto PR Merge
FROM alpine:3.18

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates

WORKDIR /app

COPY auto-merge.sh /app/auto-merge.sh
RUN chmod +x /app/auto-merge.sh

ENTRYPOINT ["/app/auto-merge.sh"]
