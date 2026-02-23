#!/bin/bash

# --------------------------------------------------
# Bitbucket Branch Cleanup Script
# --------------------------------------------------
# Deletes a given source branch across multiple repositories
# Uses the same interface as auto-merge.sh
# --------------------------------------------------

# ----------------------------
# REQUIRED ENVIRONMENT VARIABLES
# ----------------------------

if [ -z "$BASE_URL" ] || \
   [ -z "$PROJECT" ] || \
   [ -z "$USERNAME" ] || \
   [ -z "$PASSWORD" ] || \
   [ -z "$TARGET_BRANCH" ] || \
   [ -z "$SOURCE_BRANCH" ] || \
   [ -z "$REPOS" ]; then

  echo "ERROR: Missing required environment variables."
  echo "Required variables:"
  echo "  BASE_URL"
  echo "  PROJECT"
  echo "  USERNAME"
  echo "  PASSWORD"
  echo "  TARGET_BRANCH"
  echo "  SOURCE_BRANCH"
  echo "  REPOS (comma-separated list)"
  exit 1
fi

AUTH="$USERNAME:$PASSWORD"

IFS=',' read -ra REPO_ARRAY <<< "$REPOS"

echo "========================================="
echo "Starting branch deletion process"
echo "Branch to delete: $SOURCE_BRANCH"
echo "Project: $PROJECT"
echo "========================================="

# ----------------------------
# PROCESS ALL REPOSITORIES
# ----------------------------

for REPO in "${REPO_ARRAY[@]}"; do
  echo "-----------------------------------------"
  echo "Processing repository: $REPO"
  echo "-----------------------------------------"

  # Check if branch exists
  BRANCH_RESPONSE=$(curl -s -u "$AUTH" \
    "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/branches?filterText=$SOURCE_BRANCH")

  BRANCH_EXISTS=$(echo "$BRANCH_RESPONSE" | jq -r --arg BR "$SOURCE_BRANCH" \
    '.values[] | select(.displayId==$BR) | .displayId')

  if [ "$BRANCH_EXISTS" = "$SOURCE_BRANCH" ]; then
    echo "Branch $SOURCE_BRANCH exists in $REPO. Attempting deletion..."

    DELETE_RESPONSE=$(curl -s -u "$AUTH" -X DELETE \
      -H "Content-Type: application/json" \
      "$BASE_URL/rest/branch-utils/1.0/projects/$PROJECT/repos/$REPO/branches" \
      -d "{\"name\":\"refs/heads/$SOURCE_BRANCH\"}")

    # Verify deletion
    VERIFY_RESPONSE=$(curl -s -u "$AUTH" \
      "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/branches?filterText=$SOURCE_BRANCH")

    STILL_EXISTS=$(echo "$VERIFY_RESPONSE" | jq -r --arg BR "$SOURCE_BRANCH" \
      '.values[] | select(.displayId==$BR) | .displayId')

    if [ -z "$STILL_EXISTS" ]; then
      echo "SUCCESS: Branch $SOURCE_BRANCH deleted from $REPO."
    else
      echo "WARNING: Branch $SOURCE_BRANCH still exists in $REPO."
      echo "Possible reasons:"
      echo " - Branch permissions prevent deletion"
      echo " - User lacks delete permission"
      echo " - Repository hook blocked deletion"
    fi

  else
    echo "Branch $SOURCE_BRANCH does not exist in $REPO. Skipping."
  fi
done

echo "========================================="
echo "Branch deletion process completed."
echo "========================================="