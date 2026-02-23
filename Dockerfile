FROM alpine:3.18

# Install dependencies: bash, curl, jq, ca-certificates, and compatibility libraries
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates \
    libc6-compat \
    openssl

# Update CA certificates
RUN update-ca-certificates

# Set working directory
WORKDIR /app

# Copy the unified Bitbucket tool
COPY bb-tool.sh /app/bb-tool.sh

# Make the script executable
RUN chmod +x /app/bb-tool.sh

# Entrypoint
ENTRYPOINT ["/app/bb-tool.sh"]