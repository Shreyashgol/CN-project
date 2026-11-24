# Private Network Service Platform

> **Computer Networks Course Project**
> A private, multi-machine network service platform implementing DNS resolution, HTTPS/TLS, Nginx reverse proxying, round-robin load balancing, backend services, HTTP caching, and packet-level verification (**Phase 1**), extended with backup DNS, DNS TTL control, service isolation, backend failover, and DNS-based edge migration (**Phase 2**).

---

## Team Members

| # | Name                     | Roll Number  |
| - | ------------------------ | ------------ |
| 1 | **Vaageesh Kumar Singh** | `2401020073` |
| 2 | **Shreyash Golhani**     | `2401020069` |
| 3 | **Ananya Narang**        | `2401020087` |
| 4 | **Aman Kumar**           | `2401010061` |

---

## Table of Contents

### Phase 1: Build and Observe

| #  | Section                                                          |
| -- | ---------------------------------------------------------------- |
| 1  | [System Overview](#1-system-overview)                            |
| 2  | [Prerequisites](#2-prerequisites)                                |
| 3  | [Running Backend A](#3-running-backend-a--mac-3)                 |
| 4  | [Running Backend B](#4-running-backend-b--mac-4)                 |
| 5  | [DNS Server](#5-dns-server--mac-1)                               |
| 6  | [Nginx](#6-nginx--mac-2)                                         |
| 7  | [Nginx Backend Targets](#7-nginx-backend-targets)                |
| 8  | [HTTPS / TLS Certificate](#8-https--tls-certificate)             |
| 9  | [End-to-End Verification](#9-end-to-end-verification)            |
| 10 | [Response Header Verification](#10-response-header-verification) |
| 11 | [Wireshark Verification](#11-wireshark-verification)             |
| 12 | [Quick Start](#12-quick-start)                                   |

### Phase 2: Harden, Recover, Troubleshoot

| #  | Section                                                                       |
| -- | ----------------------------------------------------------------------------- |
| 13 | [Phase 2 Overview](#13-phase-2-overview)                                      |
| 14 | [Extension A: Backup DNS Resolver](#14-extension-a--backup-dns-resolver)      |
| 15 | [Extension B: DNS TTL and Record Change](#15-extension-b--dns-ttl-and-controlled-record-change) |
| 16 | [Extension C: Service Isolation](#16-extension-c--service-isolation-backend-firewall) |
| 17 | [Extension D: High-Availability Failover](#17-extension-d--high-availability-failover) |
| 18 | [Extension E: Controlled Edge Migration](#18-extension-e--controlled-edge-migration-dns-cutover) |
| 19 | [Extension F: Troubleshooting Challenge](#19-extension-f--troubleshooting-challenge) |
| 20 | [Phase 2 Quick Start](#20-phase-2-quick-start)                                |
| -- | [Documentation](#documentation)                                               |

---

# PHASE 1

---

# 1. System Overview

The Phase 1 system consists of four Macs:

| Machine   | Role                          | IP Address    | Port       |
| --------- | ----------------------------- | ------------- | ---------- |
| **Mac 1** | Private DNS Server            | `10.7.10.219` | `53/UDP`   |
| **Mac 2** | Nginx / HTTPS / Load Balancer | `10.7.26.172` | `443/TCP`  |
| **Mac 3** | Backend A                     | `10.7.6.90`   | `3001/TCP` |
| **Mac 4** | Backend B                     | `10.7.9.188`  | `3002/TCP` |

Application domain:

```
app.team_cn.test
```

DNS resolution:

```
app.team_cn.test → 10.7.26.172
```

The normal client request path is:

```
Client
   │
   │ DNS
   ▼
10.7.10.219:53
   │
   │ resolves app.team_cn.test
   ▼
10.7.26.172:443
   │
   │ Nginx + HTTPS
   │
   ├───────────────┐
   ▼               ▼
10.7.6.90:3001   10.7.9.188:3002
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
- OpenSSL
- `curl`
- `dig`
- `nc`
- Wireshark

## Install DNS software — Mac 1

```
brew install dnsmasq
```

## Install Nginx — Mac 2

```
brew install nginx
```

Backend A and Backend B use Python 3.

---

# 3. Running Backend A — Mac 3

**Machine:** Mac 3
**IP:** `10.7.6.90`
**Port:** `3001`

Backend A uses Python's `http.server`.

## Start Backend A

Open Terminal on Mac 3 and go to the Backend A directory:

```
cd backend-a
```

Start the service:

```
python3 backend_a.py
```

Backend A must listen on:

```
0.0.0.0:3001
```

## Verify Backend A

From Mac 3:

```
curl http://localhost:3001/
```

From another machine:

```
curl http://10.7.6.90:3001/
```

Status endpoint:

```
curl http://10.7.6.90:3001/api/status
```

Expected backend identity:

```
X-Backend: A
```

Check the listening port:

```
sudo lsof -nP -iTCP:3001 -sTCP:LISTEN
```

---

# 4. Running Backend B — Mac 4

**Machine:** Mac 4
**IP:** `10.7.9.188`
**Port:** `3002`

## Start Backend B

Open Terminal on Mac 4 and go to the Backend B directory:

```
cd backend-b
```

Start the service:

```
python3 backend_b.py
```

Backend B must listen on:

```
0.0.0.0:3002
```

## Verify Backend B

From Mac 4:

```
curl http://localhost:3002/
```

From another machine:

```
curl http://10.7.9.188:3002/
```

Status endpoint:

```
curl http://10.7.9.188:3002/api/status
```

Expected backend identity:

```
X-Backend: B
```

Check the listening port:

```
sudo lsof -nP -iTCP:3002 -sTCP:LISTEN
```

---

# 5. DNS Server — Mac 1

**IP:** `10.7.10.219`
**Service:** `dnsmasq`
**Port:** `53/UDP`

## Start dnsmasq

```
sudo brew services start dnsmasq
```

Check:

```
brew services list | grep dnsmasq
```

The DNS configuration should provide:

```
app.team_cn.test → 10.7.26.172
api.team_cn.test → 10.7.26.172
```

## Verify DNS directly

```
dig @10.7.10.219 app.team_cn.test
```

Expected:

```
app.team_cn.test.    A    10.7.26.172
```

Check the client DNS configuration:

```
networksetup -getdnsservers Wi-Fi
```

or:

```
scutil --dns
```

The project DNS server should be:

```
10.7.10.219
```

---

# 6. Nginx — Mac 2

**IP:** `10.7.26.172`
**Port:** `443/TCP`

Nginx acts as the HTTPS edge and load balancer.

## Test configuration

```
nginx -t
```

The configuration must report:

```
syntax is ok
test is successful
```

## Start Nginx

```
brew services start nginx
```

After configuration changes:

```
brew services restart nginx
```

Check:

```
brew services list | grep nginx
```

Verify HTTPS is listening:

```
sudo lsof -nP -iTCP:443 -sTCP:LISTEN
```

---

# 7. Nginx Backend Targets

Nginx forwards requests to:

```
Backend A → 10.7.6.90:3001
Backend B → 10.7.9.188:3002
```

The upstream configuration should contain both backend servers:

```
upstream backend_pool {
    server 10.7.6.90:3001;
    server 10.7.9.188:3002;
}
```

The application server should use:

```
server_name app.team_cn.test;
```

and forward requests to:

```
proxy_pass http://backend_pool;
```

After modifying Nginx:

```
nginx -t
brew services restart nginx
```

---

# 8. HTTPS / TLS Certificate

The project uses a self-signed certificate for:

```
app.team_cn.test
```

Generate the certificate on Mac 2:

```
mkdir -p ~/team-cn-certs
cd ~/team-cn-certs
```

```
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout app.team_cn.test.key \
  -out app.team_cn.test.crt \
  -subj "/CN=app.team_cn.test" \
  -addext "subjectAltName=DNS:app.team_cn.test"
```

Verify the SAN:

```
openssl x509 \
  -in app.team_cn.test.crt \
  -noout \
  -subject \
  -issuer \
  -ext subjectAltName
```

The certificate should contain:

```
DNS:app.team_cn.test
```

### Client-side test

Copy the certificate to the client:

```
scp app.team_cn.test.crt <user>@<client-ip>:~/
```

Then test:

```
curl --cacert ~/app.team_cn.test.crt \
https://app.team_cn.test
```

### Security

**Never commit the private key to GitHub.**

Do not commit:

```
app.team_cn.test.key
```

Recommended `.gitignore`:

```
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

```
dig app.team_cn.test
```

Expected:

```
10.7.26.172
```

If required, query the project DNS server directly:

```
dig @10.7.10.219 app.team_cn.test
```

---

## Step 2 — HTTPS

```
curl --cacert ~/app.team_cn.test.crt \
https://app.team_cn.test
```

A successful response should come from either Backend A or Backend B.

---

## Step 3 — Identify the backend

```
curl --cacert ~/app.team_cn.test.crt \
-s -D - https://app.team_cn.test \
-o /dev/null | grep -i X-Backend
```

Possible responses:

```
X-Backend: A
```

or:

```
X-Backend: B
```

---

## Step 4 — Verify both backends through Nginx

Run several independent requests:

```
for i in {1..10}; do
    curl --cacert ~/app.team_cn.test.crt \
    -s -D - https://app.team_cn.test \
    -o /dev/null | grep -i X-Backend
done
```

The output should show requests reaching both:

```
X-Backend: A
X-Backend: B
```

This provides a simple application-level verification of the Nginx load-balancing behavior.

---

# 10. Response Header Verification

Check the complete response headers:

```
curl --cacert ~/app.team_cn.test.crt \
-s -D - https://app.team_cn.test \
-o /dev/null
```

Important headers include:

```
HTTP/1.1 200 OK
X-Backend: A
Cache-Control: max-age=60
```

or:

```
X-Backend: B
Cache-Control: max-age=60
```

The project uses:

```
Cache-Control: max-age=60
```

for the required caching behavior.

### Note about `curl -I`

The backend setup does not rely on `HEAD`. Therefore, use the `GET` + `-D -` command above when inspecting response headers instead of:

```
curl -I https://app.team_cn.test
```

---

# 11. Wireshark Verification

Wireshark is used for the packet-level evidence described in the Phase 1 report.

### DNS

```
dns.qry.name == "app.team_cn.test"
```

### HTTPS / TCP

```
tcp.port == 443
```

### TLS

```
tls
```

### TLS Client Hello

```
tls.handshake.type == 1
```

### Backend A

```
ip.addr == 10.7.6.90 && tcp.port == 3001
```

### Backend B

```
ip.addr == 10.7.9.188 && tcp.port == 3002
```

### Both backends

```
tcp.port == 3001 || tcp.port == 3002
```

Useful Wireshark statistics:

```
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

```
cd backend-a
python3 backend_a.py
```

### Mac 4

```
cd backend-b
python3 backend_b.py
```

### Mac 1

```
sudo brew services start dnsmasq
```

### Mac 2

```
nginx -t
brew services start nginx
```

### Client

```
dig app.team_cn.test
```

Then:

```
curl --cacert ~/app.team_cn.test.crt \
https://app.team_cn.test
```

---

# PHASE 2

Phase 2 extends the Phase 1 system. Nothing is rebuilt: all Phase 1 machines, IPs, backends, certificate and domain stay the same.

---

# 13. Phase 2 Overview

Two Phase 1 machines take on an additional role. No new hardware is needed.

| Machine   | Phase 1 Role                  | Additional Phase 2 Role        | IP Address    |
| --------- | ----------------------------- | ------------------------------ | ------------- |
| **Mac 1** | Private DNS Server            | Primary DNS                    | `10.7.10.219` |
| **Mac 2** | Nginx / HTTPS / Load Balancer | Primary edge                   | `10.7.26.172` |
| **Mac 3** | Backend A                     | **Standby edge (nginx) + firewall** | `10.7.6.90`   |
| **Mac 4** | Backend B                     | **Backup DNS (dnsmasq) + firewall** | `10.7.9.188`  |

> **Note:** The backup (standby) nginx is assigned to **Mac 3**. It was not configured on the machine because it was not needed for the running system. It is documented in the Phase 2 report (`Phase2_Report.pdf`), and the steps in Extension E describe how it would be set up.

Phase 2 request path:

```
Client
   │
   │ DNS  (primary, then backup if the primary does not answer)
   ▼
10.7.10.219:53   ──fallback──►   10.7.9.188:53
   │
   │ resolves app.team_cn.test
   ▼
10.7.26.172:443  (primary edge)      10.7.6.90:443  (standby edge)
   │
   ├───────────────┐
   ▼               ▼
10.7.6.90:3001   10.7.9.188:3002
 Backend A         Backend B
 (ports 3001 / 3002 reachable only from the edge machines)
```

Phase 2 files are kept in `configs/`:

```
configs/
├── dnsmasq-primary.conf    Mac 1
├── dnsmasq-backup.conf     Mac 4
├── nginx-primary.conf      Mac 2
├── nginx-standby.conf      Mac 3
├── pf-backend-a.rules      Mac 3
└── pf-backend-b.rules      Mac 4
```

Evidence is stored in `evidence/phase1/` and `evidence/phase2/`.

---

# 14. Extension A — Backup DNS Resolver

**Machine:** Mac 4
**IP:** `10.7.9.188`
**Service:** `dnsmasq`
**Port:** `53/UDP`

## Install and configure

```
brew install dnsmasq
```

Use the same records as Mac 1. Only the listening address changes:

```
listen-address=10.7.9.188
```

The records must be:

```
app.team_cn.test → 10.7.26.172
api.team_cn.test → 10.7.26.172
```

Start:

```
sudo brew services start dnsmasq
```

## Verify the backup directly

```
dig @10.7.9.188 app.team_cn.test
```

Expected:

```
app.team_cn.test.    A    10.7.26.172
```

## Configure clients with both resolvers

```
networksetup -setdnsservers Wi-Fi 10.7.10.219 10.7.9.188
networksetup -getdnsservers Wi-Fi
```

## Failover demonstration

From a client (not Mac 1):

```
dig app.team_cn.test
```

On Mac 1, stop the primary:

```
sudo brew services stop dnsmasq
```

On the client:

```
dig +time=2 +tries=1 app.team_cn.test
```

Resolution continues through `10.7.9.188`.

Restore the primary afterwards:

```
sudo brew services start dnsmasq
```

### DNS failure vs. application failure

- **DNS service failure:** the name cannot be resolved at all.
- **Application server failure:** the name still resolves, but the service does not respond.

---

# 15. Extension B — DNS TTL and Controlled Record Change

## Set a short TTL

Add to the dnsmasq configuration on **Mac 1 and Mac 4**:

```
local-ttl=30
```

Restart dnsmasq on both machines:

```
sudo brew services restart dnsmasq
```

Check the TTL in the answer section:

```
dig app.team_cn.test
```

## Observe caching

Resolve from a client:

```
ping -c 1 app.team_cn.test
```

On Mac 1 and Mac 4, change the record to a different IP (for example `10.7.6.90`) and restart dnsmasq.

Resolve again from the client:

```
ping -c 1 app.team_cn.test
```

The client keeps returning the **old (cached) IP** until the 30 second TTL expires, then returns the new one.

> `dig` queries the DNS server directly and bypasses the operating system cache. Use `ping` or `curl` to demonstrate client-side caching.

## Flush the DNS cache manually

```
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

The new answer is returned immediately after the flush.

Restore the record to `10.7.26.172` after the demonstration.

### Relation to production

Before a traffic cutover, production systems lower the TTL in advance so clients move to the new server quickly.

---

# 16. Extension C — Service Isolation (Backend Firewall)

Direct access to the backend ports is restricted so that only the edge machines can reach them. The firewall rules run on both backend machines, **Mac 3** and **Mac 4**.

## Mac 3 — Backend A (`pf-backend-a.rules`)

```
pass quick on lo0
pass in quick proto tcp from 10.7.26.172 to any port 3001
block in quick proto tcp from any to any port 3001
```

`lo0` is allowed so that the standby nginx running on Mac 3 (Extension E) can still reach Backend A locally.

## Mac 4 — Backend B (`pf-backend-b.rules`)

```
pass quick on lo0
pass in quick proto tcp from { 10.7.26.172, 10.7.6.90 } to any port 3002
block in quick proto tcp from any to any port 3002
```

`10.7.6.90` is the standby edge (Extension E), which must also reach Backend B.

## Back up the original configuration

```
sudo cp /etc/pf.conf /etc/pf.conf.backup
```

## Enable the rules

Mac 3:

```
sudo pfctl -ef configs/pf-backend-a.rules
```

Mac 4:

```
sudo pfctl -ef configs/pf-backend-b.rules
```

## Verify

From a client Mac (blocked):

```
curl -m 3 http://10.7.6.90:3001/api/status
curl -m 3 http://10.7.9.188:3002/api/status
```

From Mac 2, the edge (allowed):

```
curl http://10.7.6.90:3001/api/status
curl http://10.7.9.188:3002/api/status
```

Through the edge (allowed):

```
curl --cacert ~/app.team_cn.test.crt https://app.team_cn.test
```

## Roll back

```
sudo pfctl -f /etc/pf.conf
sudo pfctl -d
```

---

# 17. Extension D — High-Availability Failover

## Nginx configuration (Mac 2)

The upstream marks a backend as failed after repeated errors:

```
upstream backend_pool {
    server 10.7.6.90:3001  max_fails=2 fail_timeout=10s;
    server 10.7.9.188:3002 max_fails=2 fail_timeout=10s;
}
```

and the proxy retries the other backend on failure:

```
location / {
    proxy_pass http://backend_pool;
    proxy_connect_timeout 2s;
    proxy_next_upstream error timeout http_502 http_503;
    add_header X-Edge primary always;
}
```

Apply:

```
nginx -t
brew services restart nginx
```

## Failover demonstration

1. Both backends running:

```
for i in {1..10}; do
    curl --cacert ~/app.team_cn.test.crt \
    -s -D - https://app.team_cn.test \
    -o /dev/null | grep -i X-Backend
done
```

`X-Backend: A` and `X-Backend: B` alternate.

2. Stop Backend A on Mac 3 and run the loop again. Every request is served by `X-Backend: B`, with no errors.

3. Start Backend A again and run the loop. Load balancing resumes across both backends.

4. Optional: stop both backends. Nginx returns `502 Bad Gateway`, while DNS and TLS still work at the edge.

## Single point of failure

The edge nginx on Mac 2 is still a single point of failure. Removing it requires a second edge node together with a floating IP (keepalived / VRRP) or DNS-level failover. Extension E demonstrates the DNS-level approach.

---

# 18. Extension E — Controlled Edge Migration (DNS Cutover)

**Standby edge:** Mac 3 (`10.7.6.90`)

> **Note:** The backup nginx on Mac 3 was not configured on the machine because it was not needed. It is documented in the Phase 2 report (`Phase2_Report.pdf`). The steps below describe the intended setup.

## Set up the standby nginx

```
brew install nginx
```

- Use the same nginx configuration as Mac 2 (`configs/nginx-standby.conf`), with `add_header X-Edge standby always;`
- Copy the same certificate and key from Mac 2 with `scp` (never through Git), and adjust the certificate paths in the config for Mac 3
- Because the certificate is issued for the name `app.team_cn.test`, it stays valid on the standby

```
nginx -t
brew services start nginx
```

## Test the standby before the cutover

```
curl --cacert ~/app.team_cn.test.crt \
--resolve app.team_cn.test:443:10.7.6.90 \
-s -D - https://app.team_cn.test -o /dev/null | grep -i X-
```

Expected: `X-Edge: standby` and an `X-Backend` header.

## Cutover

1. Client currently reaches the primary edge:

```
curl --cacert ~/app.team_cn.test.crt \
-s -D - https://app.team_cn.test -o /dev/null | grep -i X-Edge
```

```
X-Edge: primary
```

2. On Mac 1 and Mac 4, change the record to the standby and restart dnsmasq:

```
app.team_cn.test → 10.7.6.90
```

3. A client that already cached the old answer still reaches the old edge until the TTL (30 s) expires or the cache is flushed.

4. New lookups reach the standby:

```
X-Edge: standby
```

5. After the demonstration, restore:

```
app.team_cn.test → 10.7.26.172
```

---

# 19. Extension F — Troubleshooting Challenge

During evaluation one configuration fault is introduced into the running system. Diagnose it layer by layer:

| Order | Layer    | Question                       | Command                                                                  |
| ----- | -------- | ------------------------------ | ------------------------------------------------------------------------ |
| 1     | DNS      | Does the name resolve?         | `dig app.team_cn.test`                                                   |
| 2     | IP       | Is the host reachable?         | `ping 10.7.26.172`                                                       |
| 3     | TCP      | Is the port open?              | `nc -vz 10.7.26.172 443`                                                 |
| 4     | TLS      | Is the certificate valid?      | `openssl s_client -connect 10.7.26.172:443 -servername app.team_cn.test` |
| 5     | HTTP/App | What does the application say? | `curl --cacert ~/app.team_cn.test.crt -v https://app.team_cn.test`       |
| 6     | Logs     | What do the services report?   | nginx `error.log`, backend terminal output                               |

Failure behaviours observed in the project:

| Fault                      | Observation                                                      |
| -------------------------- | ---------------------------------------------------------------- |
| Wrong DNS server on client | Lookup fails, direct IP connectivity still works                 |
| DNS record with wrong IP   | Resolution succeeds, client reaches the wrong destination        |
| One backend stopped        | Edge serves all requests from the remaining backend              |
| Both backends stopped      | `502 Bad Gateway` from nginx                                     |
| Wrong destination port     | Host reachable, TCP connection to the service port fails         |

---

# 20. Phase 2 Quick Start

### Mac 1 (primary DNS)

```
sudo brew services start dnsmasq
```

### Mac 4 (backup DNS and Backend B)

```
sudo brew services start dnsmasq
cd backend-b
python3 backend_b.py
```

### Mac 3 (Backend A and standby edge)

```
cd backend-a
python3 backend_a.py
```

Standby edge (documented only, not configured; Extension E):

```
nginx -t
brew services start nginx
```

### Mac 2 (primary edge)

```
nginx -t
brew services restart nginx
```

### Client

```
networksetup -setdnsservers Wi-Fi 10.7.10.219 10.7.9.188
dig app.team_cn.test
curl --cacert ~/app.team_cn.test.crt https://app.team_cn.test
```

---

## Documentation

This README is intentionally focused on **running, testing, and reproducing the implementation** for both phases.

For deeper technical documentation, refer to:

- **`Phase1_Architecture&Report.pdf`**: architecture, implementation evidence, protocol-level analysis, Wireshark observations, screenshots, caching discussion, and Phase 1 conclusions.
- **`Phase2_Report.pdf`**: changes from Phase 1, resilience test results, troubleshooting findings, and a learning summary for each extension.