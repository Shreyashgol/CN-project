# Network Topology & Roles

## Machine Inventory

| Machine | Role | IP Address | Service & Port | Hostname / Domain |
|---|---|---|---|---|
| **Mac 1** | Primary DNS Server & Test Client | `10.7.10.219` | dnsmasq (`53/UDP`) | `dns1.team_cn.test` |
| **Mac 2** | Edge Reverse Proxy & Load Balancer | `10.7.26.172` | Nginx HTTPS (`443/TCP`) | `app.team_cn.test` |
| **Mac 3** | Backend Server A (& Standby Edge) | `10.7.6.90` | HTTP REST (`3001/TCP`) | `backend-a.team_cn.test` |
| **Mac 4** | Backend Server B (& Backup DNS) | `10.7.9.188` | HTTP REST (`3002/TCP`) | `backend-b.team_cn.test` |

## Request Flow
```
Client (Mac 1 / Mac 4)
  │
  │ 1. DNS Query: app.team_cn.test
  ▼
Mac 1 (10.7.10.219:53) ──[failover fallback]──► Mac 4 (10.7.9.188:53)
  │
  │ Returns A record: 10.7.26.172
  ▼
Mac 2 (10.7.26.172:443 - Nginx TLS Termination)
  │
  ├── Round Robin upstream (Phase 1) / Health-checked failover (Phase 2)
  ├──► Backend A (10.7.6.90:3001)
  └──► Backend B (10.7.9.188:3002)
```
