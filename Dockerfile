# Lightweight Alpine image for Bitbucket Auto Merge
FROM alpine:3.18

# Install dependencies: bash, curl, jq, ca-certificates, and compatibility libraries
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates \
    libc6-compat \
    openssl

# Update CA certificates (important for corporate HTTPS)
RUN update-ca-certificates

# Set working directory
WORKDIR /app

# Copy the auto-merge script
COPY auto-merge.sh /app/auto-merge.sh

# Make the script executable
RUN chmod +x /app/auto-merge.sh

# Entrypoint
ENTRYPOINT ["/app/auto-merge.sh"]
