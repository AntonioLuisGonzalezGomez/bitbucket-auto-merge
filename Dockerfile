# Use Alpine Linux as lightweight base
FROM alpine:3.18

# Install required packages: bash, curl, jq, ca-certificates
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates

# Set working directory
WORKDIR /app

# Copy the script
COPY auto-merge.sh /app/auto-merge.sh

# Make script executable
RUN chmod +x /app/auto-merge.sh

# Set the entrypoint to the script
ENTRYPOINT ["/app/auto-merge.sh"]
