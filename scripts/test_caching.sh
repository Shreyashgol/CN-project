#!/usr/bin/env bash
# Verify caching and conditional requests (Task F)
set -e

TARGET="https://app.team_cn.test"
CERT="$HOME/app.team_cn.test.crt"

echo "[*] Step 1: Initial request to inspect Cache-Control & ETag headers..."
curl --cacert "$CERT" -s -D - "$TARGET" -o /dev/null

echo -e "\n[*] Step 2: Testing conditional request with ETag (expecting 304 Not Modified)..."
curl --cacert "$CERT" -s -D - -H 'If-None-Match: "backend-a-v1"' "$TARGET" -o /dev/null | grep -E "(HTTP/|ETag|Cache-Control|X-Backend)"
