#!/bin/bash

# --------------------------------------------------
# Local wrapper for bbtoolrunner.sh
# Loads local configuration and invokes container
# --------------------------------------------------

# -------- CONFIGURATION --------

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

# Optional
export MIN_APPROVALS=2

# -------- PARAMETER VALIDATION --------

if [ -z "$1" ]; then
  echo "Usage:"
  echo "  $0 merge <source-branch>"
  echo "  $0 delete <source-branch>"
  exit 1
fi

ACTION="$1"
BRANCH="$2"

if [ -z "$BRANCH" ]; then
  echo "ERROR: Missing source branch"
  exit 1
fi

# -------- CALL MAIN RUNNER --------

./bbtoolrunner.sh "$ACTION" "$BRANCH"