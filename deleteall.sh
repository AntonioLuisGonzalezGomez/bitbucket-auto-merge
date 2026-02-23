#!/bin/bash

# --------------------------------------------------
# Docker Runner Script for Bitbucket Branch Deletion (Alpine)
# --------------------------------------------------

IMAGE_NAME="bitbucket-auto-merge"
PROJECT_DIR="/home/USERNAME/DEV/bitbucket-auto-merge"

# ----------------------------
# CHECK INPUT PARAMETER
# ----------------------------

if [ -z "$1" ]; then
  echo "Usage: $0 <source-branch>"
  echo "Example: $0 PARALLEL_EXECUTION"
  exit 1
fi

SOURCE_BRANCH="$1"

# ----------------------------
# VALIDATE PROJECT DIRECTORY
# ----------------------------

if [ ! -d "$PROJECT_DIR" ]; then
  echo "ERROR: Project directory not found: $PROJECT_DIR"
  exit 1
fi

if [ ! -f "$PROJECT_DIR/Dockerfile" ]; then
  echo "ERROR: Dockerfile not found in $PROJECT_DIR"
  exit 1
fi

# ----------------------------
# CONFIGURATION SECTION
# ----------------------------

BASE_URL="https://bitbucket.company.com"
PROJECT="BASE_PROJECT"
USERNAME="username"
PASSWORD="password"
TARGET_BRANCH="develop"

# Repository list as Bash array
REPOS=(
  api-gateway
  auth
)

# Convert array to CSV
REPOS_CSV=$(IFS=,; echo "${REPOS[*]}")

# ----------------------------
# BUILD DOCKER IMAGE
# ----------------------------

echo "Building Docker image from $PROJECT_DIR ..."
docker build -t "$IMAGE_NAME" "$PROJECT_DIR"

if [ $? -ne 0 ]; then
  echo "ERROR: Docker build failed."
  exit 1
fi

# ----------------------------
# RUN CONTAINER (Delete Mode)
# ----------------------------

echo "Running branch deletion container for source branch: $SOURCE_BRANCH"

docker run --rm --network=host \
  --entrypoint /app/delete-branch.sh \
  -e BASE_URL="$BASE_URL" \
  -e PROJECT="$PROJECT" \
  -e USERNAME="$USERNAME" \
  -e PASSWORD="$PASSWORD" \
  -e TARGET_BRANCH="$TARGET_BRANCH" \
  -e SOURCE_BRANCH="$SOURCE_BRANCH" \
  -e REPOS="$REPOS_CSV" \
  "$IMAGE_NAME"