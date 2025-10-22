#!/bin/bash
set -e

PANEL_URL="$1"
WEBHOOK_KEY="$2"
NTFY_TOPIC="$3"
NTFY_SERVER="${4:-https://ntfy.sh}"

RUN_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

# 🔍 Check if previous jobs in the workflow succeeded
echo "🔍 Checking previous job statuses..."
if [ -n "$GITHUB_TOKEN" ]; then
  # Get workflow run details
  WORKFLOW_RUN_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  
  # Check if any previous jobs failed
  FAILED_JOBS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "${WORKFLOW_RUN_URL}/jobs" | \
    jq -r '.jobs[] | select(.conclusion == "failure" or .conclusion == "cancelled") | .name' 2>/dev/null || echo "")
  
  if [ -n "$FAILED_JOBS" ]; then
    echo "❌ Previous jobs failed: $FAILED_JOBS"
    echo "🚫 Skipping deploy due to previous job failures"
    if [ -n "$NTFY_TOPIC" ]; then
      curl -fsS -d "🚫 Deploy skipped for ${GITHUB_REPOSITORY} due to previous job failures: $FAILED_JOBS. Check logs: ${RUN_URL}" "${NTFY_SERVER}/${NTFY_TOPIC}" || true
    fi
    exit 1
  else
    echo "✅ All previous jobs succeeded"
  fi
else
  echo "⚠️  GITHUB_TOKEN not available, cannot check previous job status"
  echo "💡 Consider using 'needs' in your workflow or providing GITHUB_TOKEN"
fi

# 🔹 Gửi request tới aaPanel
echo "🚀 Triggering deploy at ${PANEL_URL}..."
if curl -fsS -X POST "${PANEL_URL}/hook?access_key=${WEBHOOK_KEY}"; then
  echo "✅ Deploy triggered successfully!"
  # Gửi ntfy nếu có
  if [ -n "$NTFY_TOPIC" ]; then
    curl -fsS -d "✅ Deploy successful for ${GITHUB_REPOSITORY}! Check logs: ${RUN_URL}" "${NTFY_SERVER}/${NTFY_TOPIC}" || true
  fi
else
  echo "❌ Deploy failed!"
  if [ -n "$NTFY_TOPIC" ]; then
    curl -fsS -d "❌ Deploy failed for ${GITHUB_REPOSITORY}! Check logs: ${RUN_URL}" "${NTFY_SERVER}/${NTFY_TOPIC}" || true
  fi
  exit 1
fi
