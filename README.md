# Private Network Service Platform

> **Computer Networks Course Project**  
> A private, multi-machine network service platform implementing DNS resolution, HTTPS/TLS, Nginx reverse proxying, round-robin load balancing, backend services, HTTP caching, and packet-level verification.

---

## Team Members

| # | Name | Roll Number |
|---|---|---:|
| 1 | **Vaageesh Kumar Singh** | `2401020073` |
| 2 | **Shreyash Golhani** | `2401020069` |
| 3 | **Ananya Narang** | `2401020087` |
| 4 | **Aman Kumar** | `2401010061` |

---

## Table of Contents

| # | Section |
|---|---------|
| 1 | [System Overview](#1-system-overview) |
| 2 | [Running Backend A](#3-running-backend-a--mac-3) |
| 3 | [Running Backend B](#4-running-backend-b--mac-4) |
| 4 | [DNS Server](#5-dns-server--mac-1) |
| 5 | [Nginx](#6-nginx--mac-2) |
| 6 | [Nginx Backend Targets](#7-nginx-backend-targets) |
| 7 | [HTTPS / TLS Certificate](#8-https--tls-certificate) |
| 8 | [End-to-End Verification](#9-end-to-end-verification) |
| 9 | [Response Header Verification](#10-response-header-verification) |
| 10 | [Wireshark Verification](#11-wireshark-verification) |
| 11 | [Quick Start](#12-quick-start) |
| 12 | [Documentation](#documentation) |

---

# 1. System Overview

The Phase 1 system consists of four Macs:

| Machine | Role | IP Address | Port |
|---|---|---|---:|
| **Mac 1** | Private DNS Server | `10.7.20.217` | `53/UDP` |
| **Mac 2** | Nginx / HTTPS / Load Balancer | `10.7.20.207` | `443/TCP` |
| **Mac 3** | Backend A | `10.7.9.120` | `3001/TCP` |
| **Mac 4** | Backend B | `10.7.10.70` | `3002/TCP` |

Application domain:

```text
app.team_cn.test
```

DNS resolution:

```text
app.team_cn.test → 10.7.20.207
```

The normal client request path is:

```text
Client
   │
   │ DNS
   ▼
10.7.20.217:53
   │
   │ resolves app.team_cn.test
   ▼
10.7.20.207:443
   │
   │ Nginx + HTTPS
   │
   ├───────────────┐
   ▼               ▼
10.7.9.120:3001  10.7.10.70:3002
 Backend A         Backend B
```

---

# 2. Prerequisites

The following tools are required where applicable:

- macOS
- Homebrew
- Python 3
- Nginx
- dnsmasq
- FastAPI
- Uvicorn
- OpenSSL
- `curl`
- `dig`
- `nc`
- Wireshark

## Install DNS software — Mac 1

```bash
brew install dnsmasq
```

## Install Nginx — Mac 2

```bash
brew install nginx
```

## Backend B dependencies — Mac 4

```bash
python3 -m pip install fastapi uvicorn
```

Backend A uses Python's standard library.

---

## 📑 Table of Contents

| # | Section |
|---|---------|
| 1 | [System Overview](#1-system-overview) |
| 2 | [Prerequisites](#2-prerequisites) |
| 3 | [Running Backend A](#3-running-backend-a--mac-3) |
| 3.1 | [Start Backend A](#start-backend-a) |
| 3.2 | [Verify Backend A](#verify-backend-a) |
| 4 | [Running Backend B](#4-running-backend-b--mac-4) |
| 4.1 | [Install dependencies](#install-dependencies) |
| 4.2 | [Start Backend B](#start-backend-b) |
| 4.3 | [Verify Backend B](#verify-backend-b) |
| 5 | [DNS Server — Mac 1](#5-dns-server--mac-1) |
| 5.1 | [Start dnsmasq](#start-dnsmasq) |
| 5.2 | [Verify DNS directly](#verify-dns-directly) |
| 6 | [Nginx — Mac 2](#6-nginx--mac-2) |
| 6.1 | [Test configuration](#test-configuration) |
| 6.2 | [Start Nginx](#start-nginx) |
| 7 | [Nginx Backend Targets](#7-nginx-backend-targets) |
| 8 | [HTTPS / TLS Certificate](#8-https--tls-certificate) |
| 8.1 | [Client-side test](#client-side-test) |
| 8.2 | [Security](#security) |
| 9 | [End-to-End Verification](#9-end-to-end-verification) |
| 9.1 | [Step 1 — DNS](#step-1--dns) |
| 9.2 | [Step 2 — HTTPS](#step-2--https) |
| 9.3 | [Step 3 — Identify the backend](#step-3--identify-the-backend) |
| 9.4 | [Step 4 — Verify both backends through Nginx](#step-4--verify-both-backends-through-nginx) |
| 10 | [Response Header Verification](#10-response-header-verification) |
| 11 | [Wireshark Verification](#11-wireshark-verification) |
| 12 | [Quick Start](#12-quick-start) |
| — | [Documentation](#documentation) |

---

# 1. System Overview

The Phase 1 system consists of four Macs:

| Machine | Role | IP Address | Port |
|---|---|---|---:|
| **Mac 1** | Private DNS Server | `10.7.20.217` | `53/UDP` |
| **Mac 2** | Nginx / HTTPS / Load Balancer | `10.7.20.207` | `443/TCP` |
| **Mac 3** | Backend A | `10.7.9.120` | `3001/TCP` |
| **Mac 4** | Backend B | `10.7.10.70` | `3002/TCP` |

Application domain:

```text
app.team_cn.test
```

DNS resolution:

```text
app.team_cn.test → 10.7.20.207
```

The normal client request path is:

```text
Client
   │
   │ DNS
   ▼
10.7.20.217:53
   │
   │ resolves app.team_cn.test
   ▼
10.7.20.207:443
   │
   │ Nginx + HTTPS
   │
   ├───────────────┐
   ▼               ▼
10.7.9.120:3001  10.7.10.70:3002
 Backend A         Backend B
```

---

# 2. Prerequisites

The following tools are required where applicable:

- macOS
- Homebrew
- Python 3
- Nginx
- dnsmasq
- FastAPI
- Uvicorn
- OpenSSL
- `curl`
- `dig`
- `nc`
- Wireshark

## Install DNS software — Mac 1

```bash
brew install dnsmasq
```

## Install Nginx — Mac 2

```bash
brew install nginx
```

## Backend B dependencies — Mac 4

```bash
python3 -m pip install fastapi uvicorn
```

Backend A uses Python's standard library.

---

# 3. Running Backend A — Mac 3

**Machine:** Mac 3  
**IP:** `10.7.9.120`  
**Port:** `3001`

Backend A uses Python's `http.server`.

## Start Backend A

Open Terminal on Mac 3 and go to the Backend A directory:

```bash
cd backend-a
```

Start the service:

```bash
python3 backend_a.py
```

Backend A must listen on:

```text
0.0.0.0:3001
```

## Verify Backend A

From Mac 3:

```bash
curl http://localhost:3001/
```

From another machine:

```bash
curl http://10.7.9.120:3001/
```

Status endpoint:

```bash
curl http://10.7.9.120:3001/api/status
```

Expected backend identity:

```text
X-Backend: A
```

Check the listening port:

```bash
sudo lsof -nP -iTCP:3001 -sTCP:LISTEN
```

---

# 4. Running Backend B — Mac 4

**Machine:** Mac 4  
**IP:** `10.7.10.70`  
**Port:** `3002`

Backend B uses **FastAPI + Uvicorn**.

## Install dependencies

```bash
python3 -m pip install fastapi uvicorn
```

If using a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install fastapi uvicorn
```

## Start Backend B

Open Terminal on Mac 4 and go to the Backend B directory:

```bash
cd backend-b
```

Start the service:

```bash
uvicorn main:app --host 0.0.0.0 --port 3002
```

Backend B must listen on:

```text
0.0.0.0:3002
```

## Verify Backend B

From Mac 4:

```bash
curl http://localhost:3002/
```

From another machine:

```bash
curl http://10.7.10.70:3002/
```

Status endpoint:

```bash
curl http://10.7.10.70:3002/api/status
```

Expected backend identity:

```text
X-Backend: B
```

Check the listening port:

```bash
sudo lsof -nP -iTCP:3002 -sTCP:LISTEN
```

---

# 5. DNS Server — Mac 1

**IP:** `10.7.20.217`  
**Service:** `dnsmasq`  
**Port:** `53/UDP`

## Start dnsmasq

```bash
sudo brew services start dnsmasq
```

Check:

```bash
brew services list | grep dnsmasq
```

The DNS configuration should provide:

```text
app.team_cn.test → 10.7.20.207
api.team_cn.test → 10.7.20.207
```

## Verify DNS directly

```bash
dig @10.7.20.217 app.team_cn.test
```

Expected:

```text
app.team_cn.test.    A    10.7.20.207
```

Check the client DNS configuration:

```bash
networksetup -getdnsservers Wi-Fi
```

or:

```bash
scutil --dns
```

The project DNS server should be:

```text
10.7.20.217
```

---

# 6. Nginx — Mac 2

**IP:** `10.7.20.207`  
**Port:** `443/TCP`

Nginx acts as the HTTPS edge and load balancer.

## Test configuration

```bash
nginx -t
```

The configuration must report:

```text
syntax is ok
test is successful
```

## Start Nginx

```bash
brew services start nginx
```

After configuration changes:

```bash
brew services restart nginx
```

Check:

```bash
brew services list | grep nginx
```

Verify HTTPS is listening:

```bash
sudo lsof -nP -iTCP:443 -sTCP:LISTEN
```

---

# 7. Nginx Backend Targets

Nginx forwards requests to:

```text
Backend A → 10.7.9.120:3001
Backend B → 10.7.10.70:3002
```

The upstream configuration should contain both backend servers:

```nginx
upstream backend_pool {
    server 10.7.9.120:3001;
    server 10.7.10.70:3002;
}
```

The application server should use:

```nginx
server_name app.team_cn.test;
```

and forward requests to:

```nginx
proxy_pass http://backend_pool;
```

After modifying Nginx:

```bash
nginx -t
brew services restart nginx
```

---

# 8. HTTPS / TLS Certificate

The project uses a self-signed certificate for:

```text
app.team_cn.test
```

Generate the certificate on Mac 2:

```bash
mkdir -p ~/team-cn-certs
cd ~/team-cn-certs
```

```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout app.team_cn.test.key \
  -out app.team_cn.test.crt \
  -subj "/CN=app.team_cn.test" \
  -addext "subjectAltName=DNS:app.team_cn.test"
```

Verify the SAN:

```bash
openssl x509 \
  -in app.team_cn.test.crt \
  -noout \
  -subject \
  -issuer \
  -ext subjectAltName
```

The certificate should contain:

```text
DNS:app.team_cn.test
```

### Client-side test

Copy the certificate to the client:

```bash
scp app.team_cn.test.crt <user>@<client-ip>:~/
```

Then test:

```bash
curl --cacert ~/app.team_cn.test.crt \
https://app.team_cn.test
```

### Security

**Never commit the private key to GitHub.**

Do not commit:

```text
app.team_cn.test.key
```

Recommended `.gitignore`:

```gitignore
*.key
.DS_Store
__pycache__/
*.pyc
.venv/
```

---

# 9. End-to-End Verification

Once DNS, both backends, and Nginx are running:

## Step 1 — DNS

```bash
dig app.team_cn.test
```

Expected:

```text
10.7.20.207
```

If required, query the project DNS server directly:

```bash
dig @10.7.20.217 app.team_cn.test
```

---

## Step 2 — HTTPS

```bash
curl --cacert ~/app.team_cn.test.crt \
https://app.team_cn.test
```

A successful response should come from either Backend A or Backend B.

---

## Step 3 — Identify the backend

```bash
curl --cacert ~/app.team_cn.test.crt \
-s -D - https://app.team_cn.test \
-o /dev/null | grep -i X-Backend
```

Possible responses:

```text
X-Backend: A
```

or:

```text
X-Backend: B
```

---

## Step 4 — Verify both backends through Nginx

Run several independent requests:

```bash
for i in {1..10}; do
    curl --cacert ~/app.team_cn.test.crt \
    -s -D - https://app.team_cn.test \
    -o /dev/null | grep -i X-Backend
done
```

The output should show requests reaching both:

```text
X-Backend: A
X-Backend: B
```

This provides a simple application-level verification of the Nginx load-balancing behavior.

---

# 10. Response Header Verification

Check the complete response headers:

```bash
curl --cacert ~/app.team_cn.test.crt \
-s -D - https://app.team_cn.test \
-o /dev/null
```

Important headers include:

```text
HTTP/1.1 200 OK
X-Backend: A
Cache-Control: max-age=60
```

or:

```text
X-Backend: B
Cache-Control: max-age=60
```

The project uses:

```text
Cache-Control: max-age=60
```

for the required caching behavior.

### Note about `curl -I`

The backend setup does not rely on `HEAD`. Therefore, use the `GET` + `-D -` command above when inspecting response headers instead of:

```bash
curl -I https://app.team_cn.test
```

---


# 11. Wireshark Verification

Wireshark is used for the packet-level evidence described in the Phase 1 report.

### DNS

```text
dns.qry.name == "app.team_cn.test"
```

### HTTPS / TCP

```text
tcp.port == 443
```

### TLS

```text
tls
```

### TLS Client Hello

```text
tls.handshake.type == 1
```

### Backend A

```text
ip.addr == 10.7.9.120 && tcp.port == 3001
```

### Backend B

```text
ip.addr == 10.7.10.70 && tcp.port == 3002
```

### Both backends

```text
tcp.port == 3001 || tcp.port == 3002
```

Useful Wireshark statistics:

```text
Statistics → I/O Graphs
Statistics → Protocol Hierarchy
Statistics → Conversations → TCP
Statistics → Endpoints → IPv4
```

For the detailed interpretation of these captures and screenshots, refer to the **Phase 1 Architecture & Evidence Report**.

---


# 12. Quick Start

For a quick Phase 1 startup:

### Mac 3

```bash
cd backend-a
python3 backend_a.py
```

### Mac 4

```bash
cd backend-b
uvicorn main:app --host 0.0.0.0 --port 3002
```

### Mac 1

```bash
sudo brew services start dnsmasq
```

### Mac 2

```bash
nginx -t
brew services start nginx
```

### Client

```bash
dig app.team_cn.test
```

Then:

```bash
curl --cacert ~/app.team_cn.test.crt \
https://app.team_cn.test
```

---

## Documentation

This README is intentionally focused on **running, testing, and reproducing the implementation**.

For deeper technical documentation, refer to:

**`Phase1_Architecture&Report.pdf`**

The report contains the detailed project architecture, implementation evidence, protocol-level analysis, Wireshark observations, screenshots, caching discussion, and Phase 1 conclusions.

---
