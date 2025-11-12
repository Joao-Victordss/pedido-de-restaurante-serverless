#!/usr/bin/env bash
set -euo pipefail

# Wait for LocalStack to be ready. Works with older JSON health output
# and newer plain-text responses.
HOST="${1:-localhost}"
PORT="${2:-4566}"

URL="http://$HOST:$PORT/health"

echo "Aguardando LocalStack em $URL ..."
while true; do
  # Get body (silent) and status code
  BODY=$(curl -s "$URL" || true)
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo "000")

  # Debug line (uncomment for verbose): echo "STATUS=$STATUS BODY=$BODY"

  # Success conditions:
  # - JSON containing "initialized": true
  # - Body contains the word 'ready' (case-insensitive)
  # - HTTP status is 2xx
  if echo "$BODY" | grep -q '"initialized": *true' >/dev/null 2>&1; then
    break
  fi

  if echo "$BODY" | grep -qi 'ready' >/dev/null 2>&1; then
    break
  fi

  if [[ "$STATUS" =~ ^2[0-9][0-9]$ ]]; then
    break
  fi

  sleep 2
  printf '.'
done

echo
echo "LocalStack pronto."
