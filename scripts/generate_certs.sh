#!/usr/bin/env bash
# Generate self-signed TLS certificate with Subject Alternative Name (SAN)
# Run on Mac 2
set -e

CERT_DIR="$HOME/team-cn-certs"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "[*] Generating private key and certificate with SAN for app.team_cn.test..."
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout app.team_cn.test.key \
  -out app.team_cn.test.crt \
  -subj "/CN=app.team_cn.test" \
  -addext "subjectAltName=DNS:app.team_cn.test,DNS:api.team_cn.test"

echo "[*] Verifying generated certificate extensions:"
openssl x509 -in app.team_cn.test.crt -noout -subject -issuer -ext subjectAltName

echo "[+] Done. Distribute app.team_cn.test.crt to client Macs."
