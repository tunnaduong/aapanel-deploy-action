#!/bin/bash
set -e

PANEL_URL="$1"
WEBHOOK_KEY="$2"
NTFY_TOPIC="$3"
NTFY_SERVER="${4:-https://ntfy.sh}"

RUN_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

# 🔍 Check if ALL jobs in the workflow succeeded
echo "🔍 Checking ALL job statuses in workflow..."
if [ -n "$GITHUB_TOKEN" ]; then
  # Get workflow run details
  WORKFLOW_RUN_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  
  # Wait for other jobs to complete with timeout
  echo "⏳ Waiting for other jobs to complete (max 5 minutes)..."
  MAX_WAIT=300  # 5 minutes timeout
  WAIT_INTERVAL=10  # Check every 10 seconds
  ELAPSED=0
  
  while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Get all jobs and their statuses
    echo "📊 Fetching job statuses... (${ELAPSED}s elapsed)"
    JOBS_JSON=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "${WORKFLOW_RUN_URL}/jobs")
    
    # Check if ANY jobs failed
    FAILED_JOBS=$(echo "$JOBS_JSON" | jq -r '.jobs[] | select(.conclusion == "failure" or .conclusion == "cancelled") | .name' 2>/dev/null || echo "")
    RUNNING_JOBS=$(echo "$JOBS_JSON" | jq -r '.jobs[] | select(.status == "in_progress" and .name != "'"${GITHUB_JOB:-deploy}"'") | .name' 2>/dev/null || echo "")
    
    # If we have failed jobs, we can proceed immediately
    if [ -n "$FAILED_JOBS" ]; then
      echo "❌ Found failed jobs: $FAILED_JOBS"
      break
    fi
    
    # If no jobs are running, we're done
    if [ -z "$RUNNING_JOBS" ]; then
      echo "✅ All jobs completed"
      break
    fi
    
    # Still waiting
    echo "⏳ Jobs still running: $RUNNING_JOBS"
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
  done
  
  # Final status check
  echo "🔍 Final job statuses:"
  echo "$JOBS_JSON" | jq -r '.jobs[] | "\(.name): \(.status) - \(.conclusion // "running")"' 2>/dev/null || echo "Failed to parse job statuses"
  
  echo "📋 Job Summary:"
  echo "   Failed jobs: ${FAILED_JOBS:-none}"
  echo "   Running jobs: ${RUNNING_JOBS:-none}"
  
  if [ -n "$FAILED_JOBS" ]; then
    echo "❌ Some jobs failed: $FAILED_JOBS"
    echo "🚫 DEPLOY CANCELLED - Not deploying due to failed jobs"
    if [ -n "$NTFY_TOPIC" ]; then
      echo "📱 Sending failure notification - deploy cancelled"
      curl -fsS -d "❌ Deploy CANCELLED for ${GITHUB_REPOSITORY} due to failed jobs: $FAILED_JOBS. Check logs: ${RUN_URL}" "${NTFY_SERVER}/${NTFY_TOPIC}" || true
    fi
    exit 1  # ← KHÔNG deploy, chỉ thông báo fail
  elif [ -n "$RUNNING_JOBS" ]; then
    echo "⏳ Some jobs still running after timeout: $RUNNING_JOBS"
    echo "⚠️  Deploying while other jobs are still running"
  else
    echo "✅ All jobs in workflow succeeded - proceeding with deploy"
  fi
else
  echo "⚠️  GITHUB_TOKEN not available, cannot check job status"
  echo "💡 Consider using 'needs' in your workflow or providing GITHUB_TOKEN"
fi

# 🔹 Gửi request tới aaPanel
echo "🚀 Triggering deploy at ${PANEL_URL}..."
if curl -fsS -X POST "${PANEL_URL}/hook?access_key=${WEBHOOK_KEY}"; then
  echo "✅ Deploy triggered successfully!"
  
  # Gửi thông báo success (chỉ khi deploy thực sự thành công)
  if [ -n "$NTFY_TOPIC" ]; then
    echo "📱 Sending success notification - deploy completed successfully"
    curl -fsS -d "✅ Deploy successful for ${GITHUB_REPOSITORY}! All jobs passed. Check logs: ${RUN_URL}" "${NTFY_SERVER}/${NTFY_TOPIC}" || true
  fi
else
  echo "❌ Deploy failed!"
  if [ -n "$NTFY_TOPIC" ]; then
    curl -fsS -d "❌ Deploy failed for ${GITHUB_REPOSITORY}! Check logs: ${RUN_URL}" "${NTFY_SERVER}/${NTFY_TOPIC}" || true
  fi
  exit 1
fi
