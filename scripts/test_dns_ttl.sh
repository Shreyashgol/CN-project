#!/usr/bin/env bash
# Phase 2 Extension B: Test DNS TTL and OS cache invalidation
set -e

DOMAIN="app.team_cn.test"

echo "[*] Step 1: Checking TTL in DNS response (expecting 30s)..."
dig "$DOMAIN" | grep -A 2 "ANSWER SECTION"

echo "[*] Step 2: First lookup to populate OS cache..."
ping -c 1 "$DOMAIN"

echo "[*] Step 3: Demonstrating manual macOS DNS cache flush..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
echo "[+] Cache flushed successfully."
