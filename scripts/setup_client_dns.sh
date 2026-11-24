#!/usr/bin/env bash
# Configure client machine to resolve via Mac 1 (10.7.10.219)
set -e

PRIMARY_DNS="10.7.10.219"
INTERFACE="Wi-Fi"

echo "[*] Setting DNS server on interface $INTERFACE to $PRIMARY_DNS..."
networksetup -setdnsservers "$INTERFACE" "$PRIMARY_DNS"

echo "[*] Verifying current DNS servers:"
networksetup -getdnsservers "$INTERFACE"
