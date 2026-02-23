#!/bin/bash

# --------------------------------------------------
# Local wrapper for bb-tool.sh inside Docker
# Builds Docker image and runs container
# --------------------------------------------------

# -------- CONFIGURATION --------
PROJECT_DIR="/home/USERNAME/DEV/bitbucket-auto-merge"
IMAGE_NAME="bitbucket-auto-merge"

export BASE_URL="https://bitbucket.company.com"
export PROJECT="BASE_PROJECT"
export USERNAME="username"
export PASSWORD="password"
export TARGET_BRANCH="develop"

# Repository list as array
REPOS=(
  api-gateway
  auth
)

# Convert array to CSV
export REPOS=$(IFS=,; echo "${REPOS[*]}")

# Minimum approvals
export MIN_APPROVALS=2

# -------- PARAMETER VALIDATION --------
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage:"
  echo "  $0 merge <source-branch>"
  echo "  $0 delete <source-branch>"
  exit 1
fi

ACTION="$1"
BRANCH="$2"

# -------- BUILD DOCKER IMAGE --------
echo "Building Docker image from $PROJECT_DIR ..."
docker build -t "$IMAGE_NAME" "$PROJECT_DIR"

if [ $? -ne 0 ]; then
  echo "ERROR: Docker build failed."
  exit 1
fi

# -------- RUN CONTAINER --------
echo "Running $ACTION on branch $BRANCH inside Docker container ..."
docker run --rm --network=host \
  -e BASE_URL \
  -e PROJECT \
  -e USERNAME \
  -e PASSWORD \
  -e TARGET_BRANCH \
  -e REPOS \
  -e MIN_APPROVALS \
  --entrypoint /app/bb-tool.sh \
  "$IMAGE_NAME" "$ACTION" "$BRANCH"