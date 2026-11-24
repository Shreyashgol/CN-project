#!/usr/bin/env bash
# Phase 2 Extension A: Test Primary vs Backup DNS resolver failover
set -e

PRIMARY="10.7.10.219"
BACKUP="10.7.9.188"
DOMAIN="app.team_cn.test"

echo "[*] Testing Primary DNS ($PRIMARY)..."
dig @"$PRIMARY" "$DOMAIN" +noall +answer || echo "[!] Primary DNS unreachable"

echo "[*] Testing Backup DNS ($BACKUP)..."
dig @"$BACKUP" "$DOMAIN" +noall +answer || echo "[!] Backup DNS unreachable"
