#!/bin/bash

# --------------------------------------------------
# Local wrapper for bb-tool.sh inside Docker
# Supports: merge | delete | report
# --------------------------------------------------

# -------- CONFIGURATION --------
PROJECT_DIR="/home/USERNAME/DEV/bitbucket-auto-merge"
IMAGE_NAME="bitbucket-auto-merge"

export BASE_URL="https://bitbucket.company.com"
export PROJECT="BASE_PROJECT"
export USERNAME="username"
export PASSWORD="password"
export TARGET_BRANCH="develop"

# Optional config
export MIN_APPROVALS=2
export INACTIVE_DAYS=30

# Repository list as array
REPOS=(
  api-gateway
  auth
)

# Convert array to CSV
export REPOS=$(IFS=,; echo "${REPOS[*]}")

# -------- PARAMETER VALIDATION --------
if [ -z "$1" ]; then
  echo "Usage:"
  echo "  $0 merge <source-branch>"
  echo "  $0 delete <source-branch>"
  echo "  $0 report"
  exit 1
fi

ACTION="$1"
BRANCH="$2"

# For merge/delete branch is mandatory
if [[ "$ACTION" == "merge" || "$ACTION" == "delete" ]]; then
  if [ -z "$BRANCH" ]; then
    echo "Branch parameter required for $ACTION"
    exit 1
  fi
fi

# -------- BUILD DOCKER IMAGE --------
echo "Building Docker image from $PROJECT_DIR ..."
docker build -t "$IMAGE_NAME" "$PROJECT_DIR"
if [ $? -ne 0 ]; then
  echo "ERROR: Docker build failed."
  exit 1
fi

# -------- DEFAULT OUTPUT DIR FOR REPORT --------
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}/output"
mkdir -p "$OUTPUT_DIR"
REPORT_FILE="$OUTPUT_DIR/report.csv"

# -------- RUN CONTAINER --------
echo "Running $ACTION inside Docker container..."

if [ "$ACTION" == "report" ]; then
  docker run --rm --network=host \
    -e BASE_URL="$BASE_URL" \
    -e PROJECT="$PROJECT" \
    -e USERNAME="$USERNAME" \
    -e PASSWORD="$PASSWORD" \
    -e TARGET_BRANCH="$TARGET_BRANCH" \
    -e REPOS="$REPOS" \
    -e MIN_APPROVALS="$MIN_APPROVALS" \
    -e INACTIVE_DAYS="$INACTIVE_DAYS" \
    -v "$OUTPUT_DIR":/app/output \
    --entrypoint /app/bb-tool.sh \
    "$IMAGE_NAME" report > "$REPORT_FILE"

  echo "-----------------------------------------"
  echo "Report generated at: $REPORT_FILE"
  echo "-----------------------------------------"

else
  docker run --rm --network=host \
    -e BASE_URL="$BASE_URL" \
    -e PROJECT="$PROJECT" \
    -e USERNAME="$USERNAME" \
    -e PASSWORD="$PASSWORD" \
    -e TARGET_BRANCH="$TARGET_BRANCH" \
    -e REPOS="$REPOS" \
    -e MIN_APPROVALS="$MIN_APPROVALS" \
    --entrypoint /app/bb-tool.sh \
    "$IMAGE_NAME" "$ACTION" "$BRANCH"
fi