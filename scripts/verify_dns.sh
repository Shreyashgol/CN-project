#!/usr/bin/env bash
# Verify DNS resolution against Mac 1 DNS server
set -e

DNS_SERVER="10.7.10.219"
DOMAIN="app.team_cn.test"

echo "[*] Querying $DNS_SERVER for domain $DOMAIN..."
dig @"$DNS_SERVER" "$DOMAIN" +noall +answer

echo "[*] Checking resolution via system resolver..."
ping -c 1 "$DOMAIN"
