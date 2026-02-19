#!/bin/bash

# --------------------------------------------------
# Bitbucket Automatic PR Merge Script
# --------------------------------------------------
# This script:
# - Connects to Bitbucket Server REST API
# - Filters open PRs created by a specific user
# - Filters by source and target branches
# - Merges PRs with 2 or more approvals
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

# ----------------------------
# FUNCTION TO MERGE A PR
# ----------------------------
merge_pr() {
  local repo=$1
  local pr_id=$2

  DETAILS=$(curl -s -u "$AUTH" \
    "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/pull-requests/$pr_id")

  VERSION=$(echo "$DETAILS" | jq '.version')

  # Check mergeability
  MERGE_INFO=$(curl -s -u "$AUTH" \
    "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/pull-requests/$pr_id/merge")

  CAN_MERGE=$(echo "$MERGE_INFO" | jq '.conflicted == false and (.vetoes | length) == 0')

  if [ "$CAN_MERGE" = "true" ]; then
    echo "Merging PR #$pr_id in repository $repo..."
    curl -s -u "$AUTH" -X POST \
      -H "X-Atlassian-Token: no-check" \
      "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/pull-requests/$pr_id/merge?version=$VERSION"
  else
    echo "PR #$pr_id in repository $repo is not mergeable."
  fi
}

# ----------------------------
# PROCESS ALL REPOSITORIES
# ----------------------------

for REPO in "${REPO_ARRAY[@]}"; do
  echo "========================================="
  echo "Processing repository: $REPO"
  echo "========================================="

  PRS=$(curl -s -u "$AUTH" \
    "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/pull-requests?state=OPEN&at=refs/heads/$TARGET_BRANCH" \
    | jq -r --arg USER "$USERNAME" --arg SRC "$SOURCE_BRANCH" \
      '.values[] | select(.author.user.slug==$USER and .fromRef.displayId==$SRC) | .id')

  for PR in $PRS; do

    DETAILS=$(curl -s -u "$AUTH" \
      "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/pull-requests/$PR")

    APPROVED=$(echo "$DETAILS" | jq '[.reviewers[] | select(.approved == true)] | length')

    if [ "$APPROVED" -ge 2 ]; then
      merge_pr "$REPO" "$PR"
    else
      echo "PR #$PR in repository $REPO has $APPROVED approvals. At least 2 required."
    fi
  done
done
