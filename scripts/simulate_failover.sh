#!/usr/bin/env bash
# Phase 2 Extension D: Verify high-availability load balancing & failover
set -e

TARGET="https://app.team_cn.test"
CERT="$HOME/app.team_cn.test.crt"

echo "[*] Sending 10 requests to observe round-robin distribution and X-Backend header..."
for i in {1..10}; do
    RES=$(curl --cacert "$CERT" -s -D - "$TARGET" -o /dev/null | grep -iE "(X-Backend|X-Edge)")
    echo "Request $i: $RES"
done
