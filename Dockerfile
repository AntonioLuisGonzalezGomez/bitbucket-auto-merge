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

# Copy scripts
COPY auto-merge.sh /app/auto-merge.sh
COPY delete-branch.sh /app/delete-branch.sh

# Make scripts executable
RUN chmod +x /app/auto-merge.sh \
    /app/delete-branch.sh

# Default entrypoint (auto-merge)
ENTRYPOINT ["/app/auto-merge.sh"]