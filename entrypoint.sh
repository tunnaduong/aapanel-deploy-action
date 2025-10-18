#!/bin/bash
set -e

PANEL_URL="$1"
WEBHOOK_KEY="$2"
NTFY_TOPIC="$3"
NTFY_SERVER="${4:-https://ntfy.sh}"

RUN_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

# 🔹 Gửi request tới aaPanel
echo "🚀 Triggering deploy at ${PANEL_URL}..."
if curl -fsS -X POST "${PANEL_URL}/hook?access_key=${WEBHOOK_KEY}"; then
  echo "✅ Deploy triggered successfully!"
  # Gửi ntfy nếu có
  if [ -n "$NTFY_TOPIC" ]; then
    curl -fsS -d "✅ Deploy successful for ${GITHUB_REPOSITORY}! ${RUN_URL}" "${NTFY_SERVER}/${NTFY_TOPIC}" || true
  fi
else
  echo "❌ Deploy failed!"
  if [ -n "$NTFY_TOPIC" ]; then
    curl -fsS -d "❌ Deploy failed for ${GITHUB_REPOSITORY}! ${RUN_URL}" "${NTFY_SERVER}/${NTFY_TOPIC}" || true
  fi
  exit 1
fi
