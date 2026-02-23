#!/bin/bash

# --------------------------------------------------
# Bitbucket Automation Tool
# --------------------------------------------------
# Usage: ./bb-tool.sh <merge|delete> <source-branch>
# --------------------------------------------------

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <merge|delete> <source-branch>"
  exit 1
fi

COMMAND="$1"
SOURCE_BRANCH="$2"

# Validate environment variables
if [ -z "$BASE_URL" ] || \
   [ -z "$PROJECT" ] || \
   [ -z "$USERNAME" ] || \
   [ -z "$PASSWORD" ] || \
   [ -z "$TARGET_BRANCH" ] || \
   [ -z "$REPOS" ]; then
  echo "ERROR: Missing required environment variables."
  exit 1
fi

AUTH="$USERNAME:$PASSWORD"
MIN_APPROVALS="${MIN_APPROVALS:-2}"
IFS=',' read -ra REPO_ARRAY <<< "$REPOS"

# ----------------------------
# Merge PR function
# ----------------------------
merge_pr() {
  local repo=$1
  local pr_id=$2

  DETAILS=$(curl -s -u "$AUTH" \
    "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/pull-requests/$pr_id")
  VERSION=$(echo "$DETAILS" | jq '.version')

  MERGE_INFO=$(curl -s -u "$AUTH" \
    "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/pull-requests/$pr_id/merge")
  CAN_MERGE=$(echo "$MERGE_INFO" | jq '.conflicted == false and (.vetoes | length) == 0')

  if [ "$CAN_MERGE" = "true" ]; then
    echo "Merging PR #$pr_id in $repo..."
    curl -s -u "$AUTH" -X POST \
      -H "X-Atlassian-Token: no-check" \
      "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/pull-requests/$pr_id/merge?version=$VERSION&deleteSourceBranch=true"
    echo "PR #$pr_id merged and source branch deleted if possible."
  else
    echo "PR #$pr_id in $repo is not mergeable."
  fi
}

# ----------------------------
# Delete branch function
# ----------------------------
delete_branch() {
  local repo=$1
  local branch=$2

  echo "Deleting branch '$branch' in $repo if it exists..."

  # Check if branch exists
  EXISTS=$(curl -s -u "$AUTH" \
    "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/branches?filterText=$branch" \
    | jq -r '.values[] | select(.displayId=="'"$branch"'") | .id')

  if [ -n "$EXISTS" ]; then
    curl -s -u "$AUTH" -X DELETE \
      -H "Content-Type: application/json" \
      "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/branches?name=$branch&dryRun=false"
    echo "Branch '$branch' deleted in $repo."
  else
    echo "Branch '$branch' does not exist in $repo."
  fi
}

# ----------------------------
# Main loop
# ----------------------------
for REPO in "${REPO_ARRAY[@]}"; do
  echo "========================================="
  echo "Processing repository: $REPO"
  echo "========================================="

  case "$COMMAND" in
    merge)
      PRS=$(curl -s -u "$AUTH" \
        "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/pull-requests?state=OPEN&at=refs/heads/$TARGET_BRANCH" \
        | jq -r --arg USER "$USERNAME" --arg SRC "$SOURCE_BRANCH" \
          '.values[] | select(.author.user.slug==$USER and .fromRef.displayId==$SRC) | .id')

      for PR in $PRS; do
        DETAILS=$(curl -s -u "$AUTH" \
          "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/pull-requests/$PR")

        APPROVED=$(echo "$DETAILS" | jq '[.reviewers[] | select(.approved == true)] | length')

        if [ "$APPROVED" -ge "$MIN_APPROVALS" ]; then
          merge_pr "$REPO" "$PR"
        else
          echo "PR #$PR in $REPO has $APPROVED approvals. Min required: $MIN_APPROVALS."
        fi
      done
      ;;
    delete)
      delete_branch "$REPO" "$SOURCE_BRANCH"
      ;;
    *)
      echo "Unknown command: $COMMAND. Use merge or delete."
      exit 1
      ;;
  esac
done