#!/bin/bash

# --------------------------------------------------
# Docker Runner Script for Bitbucket Auto Merge (Alpine)
# --------------------------------------------------

IMAGE_NAME="bitbucket-auto-merge"

# ----------------------------
# CONFIGURATION SECTION
# ----------------------------

BASE_URL="https://bitbucket.oberthur.com"
PROJECT="OTAP"
USERNAME="your_username"
PASSWORD="your_password"
TARGET_BRANCH="develop"
SOURCE_BRANCH="PARALLEL_EXECUTION"
REPOS="api-gateway,audit,auth,devices,notifications"

# Minimum approvals required to merge
MIN_APPROVALS=2

# ----------------------------
# BUILD DOCKER IMAGE
# ----------------------------

echo "Building lightweight Docker image..."
docker build -t $IMAGE_NAME .

# ----------------------------
# RUN CONTAINER
# ----------------------------

echo "Running auto-merge container..."

docker run --rm \
  -e BASE_URL="$BASE_URL" \
  -e PROJECT="$PROJECT" \
  -e USERNAME="$USERNAME" \
  -e PASSWORD="$PASSWORD" \
  -e TARGET_BRANCH="$TARGET_BRANCH" \
  -e SOURCE_BRANCH="$SOURCE_BRANCH" \
  -e REPOS="$REPOS" \
  -e MIN_APPROVALS="$MIN_APPROVALS" \
  $IMAGE_NAME
