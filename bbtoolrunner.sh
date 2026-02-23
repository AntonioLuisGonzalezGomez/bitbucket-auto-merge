#!/bin/bash

# ----------------------------
# Usage: run.sh <merge|delete> <source-branch>
# ----------------------------

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <merge|delete> <source-branch>"
  exit 1
fi

COMMAND="$1"
SOURCE_BRANCH="$2"
PROJECT_DIR="/home/USERNAME/DEV/bitbucket-auto-merge"
IMAGE_NAME="bitbucket-auto-merge"

# ----------------------------
# Configuration
# ----------------------------
BASE_URL="https://bitbucket.company.com"
PROJECT="BASE_PROJECT"
USERNAME="username"
PASSWORD="password"
TARGET_BRANCH="develop"

# Repos as Bash array
REPOS=(
  api-gateway
  auth
)

# Convert to CSV
REPOS_CSV=$(IFS=,; echo "${REPOS[*]}")

# Minimum approvals
MIN_APPROVALS=2

# ----------------------------
# Build Docker image
# ----------------------------
docker build -t "$IMAGE_NAME" "$PROJECT_DIR"

# ----------------------------
# Run container
# ----------------------------
docker run --rm --network=host \
  -e BASE_URL="$BASE_URL" \
  -e PROJECT="$PROJECT" \
  -e USERNAME="$USERNAME" \
  -e PASSWORD="$PASSWORD" \
  -e TARGET_BRANCH="$TARGET_BRANCH" \
  -e REPOS="$REPOS_CSV" \
  -e MIN_APPROVALS="$MIN_APPROVALS" \
  --entrypoint /app/bb-tool.sh \
  "$IMAGE_NAME" "$COMMAND" "$SOURCE_BRANCH"