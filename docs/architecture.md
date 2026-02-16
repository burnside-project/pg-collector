# Architecture Overview

How PG Collector works — from data collection to AI-powered predictions.

---

## How It Works

PG Collector is a lightweight agent that runs in your environment alongside PostgreSQL. It collects database telemetry and streams it to the Burnside platform for AI-powered analysis and prediction.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Your Environment                            │
│                                                                     │
│  ┌─────────────────┐         ┌─────────────────────────────┐       │
│  │   PostgreSQL    │         │   PG Collector              │       │
│  │                 │◀───────▶│   (single binary)           │       │
│  │  RDS / Aurora / │  query  │                             │       │
│  │  Cloud SQL /    │         │  - Queries pg_stat_* views  │       │
│  │  Self-hosted    │         │  - Buffers data locally     │       │
│  │                 │         │  - Streams to Burnside      │       │
│  └─────────────────┘         └──────────────┬──────────────┘       │
│                                             │                      │
└─────────────────────────────────────────────┼──────────────────────┘
                                              │ HTTPS (port 443)
                                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Burnside Platform                             │
│                                                                     │
│   Ingestion → Storage → Feature Extraction → AI/ML → Predictions   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Key properties:**

- **Single binary** — no JVM, no Python runtime, no external dependencies
- **Read-only** — only queries PostgreSQL system views, never modifies your data
- **Low resource** — minimal RAM and CPU footprint, max 2 PostgreSQL connections, timeout-protected queries
- **Resilient** — local buffering survives network outages with zero data loss

---

## Data Flow

```
PostgreSQL ──▶ Scheduler ──▶ Samplers ──▶ Local Buffer ──▶ Cloud Streaming
```

1. **Scheduler** triggers each sampler at its configured interval
2. **Samplers** query PostgreSQL system views (`pg_stat_activity`, `pg_stat_database`, etc.)
3. **Local Buffer** holds samples in memory with automatic disk overflow for resilience
4. **Output** sends batched data to the configured destination

When a network outage occurs, data accumulates in the local buffer and drains automatically when connectivity is restored.

---

## What We Collect

PG Collector includes 12 PostgreSQL metric samplers in two groups. Which samplers run depends on your [subscription plan](plans.md).

### Core Samplers

| Sampler | PostgreSQL View | What You Learn |
|---------|----------------|----------------|
| **activity** | `pg_stat_activity` | Active sessions, wait events, blocked queries |
| **database** | `pg_stat_database` | Transaction rates, cache hit ratios, deadlocks |
| **statements** | `pg_stat_statements` | Slow queries, execution plans, call counts |
| **bgwriter** | `pg_stat_bgwriter` | Checkpoint frequency, buffer write pressure |
| **replication** | `pg_stat_replication` | Replication lag (time and bytes), sync state |
| **vacuum** | `pg_stat_user_tables` | Dead tuples, vacuum progress, wraparound risk |

### Extended Samplers

| Sampler | PostgreSQL View | What You Learn |
|---------|----------------|----------------|
| **locks** | `pg_locks` | Lock contention, blocking chains, deadlock risk |
| **wal** | `pg_stat_wal` | WAL generation rate, archiver status |
| **slots** | `pg_replication_slots` | Replication slot lag, inactive slots |
| **wal_receiver** | `pg_stat_wal_receiver` | Standby receive lag |
| **statio** | `pg_statio_user_tables` | Table and index I/O statistics |
| **bloat** | `pg_class` | Table and index bloat estimation |

See [Subscription Plans](plans.md) for sampler availability by plan.

---

## Deployment Scenarios

### Bare Metal / VM (Most Common)

A VM or bare metal server with network access to PostgreSQL. This is the simplest and most common deployment.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Your Infrastructure                              │
│                                                                      │
│  ┌─────────────────┐              ┌─────────────────────────────┐   │
│  │   PostgreSQL    │   TCP/5432   │     Monitoring VM            │   │
│  │                 │◄────────────►│                              │   │
│  │  - RDS/Aurora   │              │  ┌────────────────────────┐  │   │
│  │  - Cloud SQL    │              │  │    pg-collector         │  │   │
│  │  - Self-hosted  │              │  │    (single binary)      │  │   │
│  │  - On-prem      │              │  └───────────┬────────────┘  │   │
│  └─────────────────┘              │              │               │   │
│                                   │              │ HTTPS/443     │   │
│                                   └──────────────┼───────────────┘   │
│                                                  │                   │
└──────────────────────────────────────────────────┼───────────────────┘
                                                   ▼
                                    ┌─────────────────────────────┐
                                    │   Burnside Platform         │
                                    └─────────────────────────────┘
```

**Requirements:** Any Linux/macOS machine with network access to PostgreSQL and outbound HTTPS.

### Same Host as PostgreSQL

Run the collector directly on the PostgreSQL server — simplest network setup.

```
┌─────────────────────────────────────────┐
│         PostgreSQL Server               │
│                                         │
│  ┌─────────────────┐  ┌──────────────┐ │
│  │   PostgreSQL    │  │ pg-collector │ │
│  │   (localhost)   │◄─│              │ │
│  └─────────────────┘  └──────┬───────┘ │
│                              │         │
└──────────────────────────────┼─────────┘
                               │ HTTPS/443
                               ▼
                    ┌─────────────────────┐
                    │  Burnside Platform  │
                    └─────────────────────┘
```

No network configuration needed for the PostgreSQL connection. Not recommended for high-load production databases since it shares server resources.

### Docker / Container

Run as a container with network access to PostgreSQL:

```bash
docker run -d \
  --name pg-collector \
  -e PG_CONN_STRING="postgres://pgcollector@db-host:5432/postgres?sslmode=verify-full" \
  -e API_KEY="pgc_pro_xxx" \
  -v /var/lib/pg-collector:/var/lib/pg-collector \
  burnside/pg-collector:latest
```

Network options: `--network host` (simplest), `--network bridge` (ensure PostgreSQL is reachable), or Docker Compose with service names.

### Cloud VPC (AWS / GCP / Azure)

For managed databases (RDS, Cloud SQL, Azure Database), deploy the collector in the same VPC/VNET:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Your VPC                                     │
│                                                                      │
│  ┌─────────────────┐              ┌─────────────────────────────┐   │
│  │ RDS / Aurora /  │  Private IP  │  EC2 / GCE / Azure VM       │   │
│  │ Cloud SQL       │◄────────────►│  (pg-collector)              │   │
│  └─────────────────┘              └──────────────┬──────────────┘   │
│                                                  │                   │
└──────────────────────────────────────────────────┼───────────────────┘
                                                   │ NAT Gateway
                                                   ▼ (outbound only)
                                    ┌─────────────────────────────┐
                                    │   Burnside Platform         │
                                    └─────────────────────────────┘
```

| Cloud | Database | Auth Method |
|-------|----------|-------------|
| AWS | RDS / Aurora | IAM Auth (`auth_method: aws_iam`) |
| GCP | Cloud SQL | IAM Auth via Cloud SQL Auth Proxy |
| Azure | Azure Database | AAD Auth |

See [AWS Setup](aws-setup.md) and [GCP Setup](gcp-setup.md) for cloud-specific guides.

### Kubernetes

Deploy as a Deployment with secrets for credentials:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pg-collector
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: pg-collector
        image: burnside/pg-collector:latest
        env:
        - name: PG_CONN_STRING
          valueFrom:
            secretKeyRef:
              name: pg-credentials
              key: conn_string
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: burnside-api
              key: api_key
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "250m"
```

---

## Resilience

PG Collector is designed to never lose data, even during outages.

### Two-Tier Buffering

1. **Memory buffer** — holds recent samples in memory for fast access
2. **Disk buffer** — when the memory buffer is full, samples overflow to persistent storage on disk
3. **Automatic drain** — when the output destination reconnects, the disk buffer drains automatically in order

### Grace Period

If the Burnside platform is unreachable, the collector enters **grace mode** and continues collecting metrics using its cached configuration. If connectivity is restored within the grace period, buffered data is flushed and normal operation resumes. See [Subscription Plans](plans.md) for grace period by plan.

### Circuit Breakers

All external connections are protected by circuit breakers. When failures exceed a threshold, the circuit opens and the collector stops attempting that connection. The circuit automatically resets after a timeout, preventing cascade failures and allowing recovery.

---

## Resource Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **CPU** | 0.1 vCPU | 0.25 vCPU |
| **Memory** | 64 MB | 128 MB |
| **Disk** | 100 MB | 500 MB |
| **Network** | Outbound HTTPS (port 443) | — |

---

## Network Requirements

| Connection | Direction | Port | Required |
|-----------|-----------|------|----------|
| Collector to PostgreSQL | Outbound | 5432 (or custom) | Yes |
| Collector to Burnside Platform | Outbound | 443 (HTTPS) | Yes (except local-only demo mode) |
| Health endpoints | Inbound | 8080 (configurable) | Optional (for monitoring) |

!!! note

    PG Collector requires **no inbound ports** for normal operation. Health endpoints on port 8080 are optional and only needed if you want to integrate with load balancers, Kubernetes probes, or Prometheus scraping.

---

## Related Documentation

- [Subscription Plans](plans.md) — Compare plans and features
- [Device Activation](activation.md) — How collectors activate and authenticate
- [Configuration Guide](configuration.md) — Full configuration reference
- [Monitoring](monitoring.md) — Health endpoints and Prometheus metrics
