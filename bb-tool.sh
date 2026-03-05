#!/bin/bash

# --------------------------------------------------
# Bitbucket Automation Tool
# --------------------------------------------------
# Usage: ./bb-tool.sh <merge|delete|report> <source-branch>
# --------------------------------------------------

COMMAND="$1"
SOURCE_BRANCH="$2"

# ----------------------------
# Validate environment variables
# ----------------------------
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
INACTIVE_DAYS="${INACTIVE_DAYS:-30}"
IFS=',' read -ra REPO_ARRAY <<< "$REPOS"

# ----------------------------
# Merge PR function
# ----------------------------
merge_pr() {
  local repo=$1
  local pr_id=$2

  # Get PR details
  DETAILS=$(curl -s -u "$AUTH" \
    "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$repo/pull-requests/$pr_id")
  VERSION=$(echo "$DETAILS" | jq '.version')

  # Check mergeability
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
    # Delete branch
    curl -s -u "$AUTH" -X DELETE \
      -H "Content-Type: application/json" \
      "$BASE_URL/rest/branch-utils/1.0/projects/$PROJECT/repos/$repo/branches" \
      -d "{\"name\":\"refs/heads/$branch\"}"
    echo ">>>>> ACTION DONE: Branch '$branch' deleted in $repo."
  else
    echo "Branch '$branch' does not exist in $repo."
  fi
}

# ----------------------------
# Report function
# ----------------------------
generate_report() {
  REPORT_FILE="${REPORT_FILE:-output/report.csv}"
  echo "Repository,Branch,Author,LastCommit,DaysSinceLastCommit,Reason,Case" > "$REPORT_FILE"

  for REPO in "${REPO_ARRAY[@]}"; do
    # Get all branches
    BRANCHES=$(curl -s -u "$AUTH" \
      "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/branches?limit=1000" \
      | jq -r '.values[] | .displayId')

    for BR in $BRANCHES; do
      [ "$BR" == "$TARGET_BRANCH" ] && continue

      # Last commit info
      LAST_COMMIT_INFO=$(curl -s -u "$AUTH" \
        "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/commits?until=$BR&limit=1" \
        | jq -r '.values[0] | "\(.author.name // "N/A"),\(.authorTimestamp // 0)"')
      AUTHOR=$(echo "$LAST_COMMIT_INFO" | cut -d',' -f1)
      TIMESTAMP=$(echo "$LAST_COMMIT_INFO" | cut -d',' -f2)

      if [ "$TIMESTAMP" == "0" ] || [ "$TIMESTAMP" == "null" ] || [ -z "$TIMESTAMP" ]; then
        DAYS_INACTIVE="N/A"
        LAST_COMMIT_DATE="N/A"
      else
        NOW=$(date +%s)
        COMMIT_SEC=$((TIMESTAMP / 1000))
        DAYS_INACTIVE=$(( (NOW - COMMIT_SEC) / 86400 ))
        LAST_COMMIT_DATE=$(date -d @"$COMMIT_SEC" "+%Y-%m-%d")
      fi

      # ------------------------------
      # Get all historical PRs from this branch
      # ------------------------------
      PR_INFO=$(curl -s -u "$AUTH" \
        "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/pull-requests?state=ALL&limit=1000" \
        | jq -r --arg BR "$BR" '[.values[] | select(.fromRef.displayId==$BR)] | .[]? | .state')

      PR_MERGED=false
      PR_DECLINED=false
      PR_OPEN=false

      if [ -n "$PR_INFO" ]; then
        while IFS= read -r STATE; do
          case "$STATE" in
            MERGED) PR_MERGED=true ;;
            DECLINED) PR_DECLINED=true ;;
            OPEN) PR_OPEN=true ;;
          esac
        done <<< "$PR_INFO"
      fi

      # ------------------------------
      # Determine reason and case based on priority
      # ------------------------------
      if [ "$PR_MERGED" = true ]; then
        REASON="PR merged"
        CASE="🔴 MERGED"
      elif [ "$PR_DECLINED" = true ]; then
        REASON="PR declined"
        CASE="🟠 PR_DECLINED"
      else
        COMMITS_NOT_IN_TARGET=$(curl -s -u "$AUTH" \
          "$BASE_URL/rest/api/latest/projects/$PROJECT/repos/$REPO/commits?until=$BR&since=$TARGET_BRANCH&limit=1" \
          | jq '.size // 0')

        if [ "$COMMITS_NOT_IN_TARGET" -eq 0 ]; then
          REASON="No commits"
          CASE="🟠 NO_COMMITS"
        elif [ "$DAYS_INACTIVE" != "N/A" ] && [ "$DAYS_INACTIVE" -ge "$INACTIVE_DAYS" ]; then
          REASON="Inactive > $INACTIVE_DAYS days"
          CASE="🟡 INACTIVE"
        elif [ "$PR_OPEN" = true ]; then
          REASON="Active PR open"
          CASE="⚪ No problems"
        else
          REASON="No open PR"
          CASE="🔵 NO_PR"
        fi
      fi

      echo "$REPO,$BR,$AUTHOR,$LAST_COMMIT_DATE,$DAYS_INACTIVE,$REASON,$CASE" >> "$REPORT_FILE"
    done
  done

  # Automatically generate ranking after report
  generate_ranking
}

# ----------------------------
# Generate ranking by author
# ----------------------------
generate_ranking() {
  RANKING_FILE="${REPORT_FILE%.csv}_ranking.csv"
  echo "Author,MERGED,PR_DECLINED,NO_COMMITS,INACTIVE,No problems,NO_PR" > "$RANKING_FILE"

  # Get unique authors
  AUTHORS=$(tail -n +2 "$REPORT_FILE" | cut -d',' -f3 | sort | uniq)

  for AUTHOR in $AUTHORS; do
    MERGED_COUNT=$(grep -F ",$AUTHOR," "$REPORT_FILE" | grep -F "🔴 MERGED" | wc -l)
    DECLINED_COUNT=$(grep -F ",$AUTHOR," "$REPORT_FILE" | grep -F "🟠 PR_DECLINED" | wc -l)
    NO_COMMITS_COUNT=$(grep -F ",$AUTHOR," "$REPORT_FILE" | grep -F "🟠 NO_COMMITS" | wc -l)
    INACTIVE_COUNT=$(grep -F ",$AUTHOR," "$REPORT_FILE" | grep -F "🟡 INACTIVE" | wc -l)
    ACTIVE_PR_COUNT=$(grep -F ",$AUTHOR," "$REPORT_FILE" | grep -F "⚪ No problems" | wc -l)
    NO_PR_COUNT=$(grep -F ",$AUTHOR," "$REPORT_FILE" | grep -F "🔵 NO_PR" | wc -l)

    echo "$AUTHOR,$MERGED_COUNT,$DECLINED_COUNT,$NO_COMMITS_COUNT,$INACTIVE_COUNT,$ACTIVE_PR_COUNT,$NO_PR_COUNT" >> "$RANKING_FILE"
  done
}

# ----------------------------
# Main loop
# ----------------------------
case "$COMMAND" in
  merge)
    for REPO in "${REPO_ARRAY[@]}"; do
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
    done
    ;;
  delete)
    for REPO in "${REPO_ARRAY[@]}"; do
      delete_branch "$REPO" "$SOURCE_BRANCH"
    done
    ;;
  report)
    generate_report
    ;;
  *)
    echo "Unknown command: $COMMAND. Use merge, delete or report."
    exit 1
    ;;
esac