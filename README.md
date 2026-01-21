<p align="center">
  <h1 align="center">PG Collector</h1>
** Distribution Repository** — This repository contains release binaries, installation scripts, and documentation for PG Collector. The collector source code is proprietary. For licensing inquiries, contact (mailto:licensing@burnsideproject.ai).
  <p align="center">
    <strong>From Signals to Prediction</strong>
  </p>
  <p align="center">
    <em>Edge Compute Agent for AI-Powered PostgreSQL Intelligence</em>
  </p>

<p align="center">
  <a href="https://github.com/burnside-project/pg-collector/releases"><img src="https://img.shields.io/github/v/release/burnside-project/pg-collector?style=flat-square" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Community%20Freeware-orange?style=flat-square" alt="License"></a>
  <a href="https://github.com/burnside-project/pg-collector/releases"><img src="https://img.shields.io/github/downloads/burnside-project/pg-collector/total?style=flat-square" alt="Downloads"></a>
  <img src="https://img.shields.io/badge/AI--Powered-Claude%203.5%20Haiku-blueviolet?style=flat-square" alt="AI Powered">
</p>

<p align="center">
  <a href="#quick-install">Install</a> |
  <a href="#features">Features</a> |
  <a href="#ai-powered-prediction">AI Prediction</a> |
  <a href="#subscription-tiers">Tiers</a> |
  <a href="docs/quick-start.md">Quick Start</a> |
  <a href="docs/configuration.md">Configuration</a>
</p>

---

## Overview

**Stop reacting to database issues—start predicting them.**

PG Collector is the **edge compute agent** in our AI-powered observability pipeline. It extracts PostgreSQL metrics at the edge and streams them to our cloud infrastructure (AWS + GCP), where Claude 3.5 Haiku analyzes patterns and predicts issues before they impact your users.

**A single binary. Zero dependencies. 5-minute setup. Cloud-powered AI predictions.**

```
                          EDGE                                              CLOUD
┌──────────────┐      ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   Signals    │ ───▶ │ PG Collector │ ───▶ │  AWS + GCP   │ ───▶ │ Predictions  │
│ (pg_stat_*)  │      │ (Edge Agent) │      │ Claude Haiku │      │  & Actions   │
└──────────────┘      └──────────────┘      └──────────────┘      └──────────────┘
        │                    │                      │                     │
   Your Database      Feature Extraction     AI Classification      Slack/PagerDuty
```

**Why Teams Choose PG Collector:**

| | |
|---|---|
| **AI-Powered Predictions** | Claude 3.5 Haiku analyzes patterns and predicts issues before they happen |
| **From Signals to Action** | Raw metrics become actionable predictions with recommended fixes |
| **Zero Database Impact** | Designed from the ground up to never affect your database performance |
| **No DBA Required** | AI explains complex issues in plain language with specific actions |
| **Works Everywhere** | RDS, Aurora, Cloud SQL, or self-managed—we've got you covered |
| **Never Lose Data** | Resilient buffering survives network hiccups without dropping metrics |

---

## Local LLM Demo Testing

> **Want to try AI-powered analysis without the cloud?**

The `demo-agent/` directory includes a **standalone local testing tool** that lets you analyze pg-collector telemetry using your own LLM (ChatGPT, Claude, etc.). No API keys or cloud infrastructure required.

<a href="https://burnsideproject.ai/download/pg-collector-agent-demo">Download pg-collector agent demo</a>

### The demo is limited by design.
- It captures only what was active during the runtime window (e.g., 10 minutes, 1 hour).
- Certain datasets are intentionally capped or filtered (for example, top queries by total execution time).
- Some collectors (such as deeper table- and index-level telemetry) are not enabled in the demo to keep the footprint small and evaluation-friendly.

### The demo is meant to be illustrative, not exhaustive.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Your Environment (Edge Only)                        │
│                                                                         │
│  PostgreSQL ──→ pg-collector ──→ ./telemetry/*.jsonl                   │
│                 (single binary)         │                               │
│                                         ▼                               │
│                              ./prepare-snapshot.sh                      │
│                                         │                               │
│                                         ▼                               │
│                              telemetry-snapshot.json ──→ Your LLM      │
└─────────────────────────────────────────────────────────────────────────┘
```

### Quick Start (Demo)

```bash
# 1. Run collector in local-only mode
pg-collector --config config.yaml  # with output_mode: local_only

# 2. Prepare a snapshot
cd demo-agent
./prepare-snapshot.sh -d ../telemetry -m 15

# 3. Upload telemetry-snapshot.json to ChatGPT/Claude
#    Paste a prompt from prompts/ directory
```

<img src="https://github.com/user-attachments/assets/3e59f594-ebf3-4a37-9d44-c5ce8984345f" />

---

<img src="https://github.com/user-attachments/assets/aabf9664-1291-4c9b-8b6c-ec3f535475ac" />




### What's Included

| Prompt | Use Case |
|--------|----------|
| `01-health-check.md` | General database health assessment |
| `02-slow-queries.md` | Query performance optimization |
| `03-incident-investigation.md` | Diagnose active problems |
| `04-capacity-planning.md` | Resource utilization and scaling |
| `05-quick-diagnosis.md` | Fast 30-second triage |

### Demo vs. Full Platform

| Capability | Demo (Local) | Full SaaS Platform |
|------------|:------------:|:------------------:|
| Single binary, runs locally | ✅ | ✅ |
| Real-time streaming | ❌ | ✅ |
| Continuous monitoring | ❌ | ✅ |
| Automated alerts (Slack/PagerDuty) | ❌ | ✅ |
| Historical analysis (7–90 days) | ❌ | ✅ |
| Predictive AI pipeline | ❌ | ✅ |

**See [demo-agent/README.md](demo-agent/README.md) for full documentation.**

---

## Manual Download

Download the latest release from the [Releases page](https://github.com/burnside-project/pg-collector/releases).

| Platform | Architecture | File |
|----------|--------------|------|
| **Linux** | x86_64 (amd64) | `pg-collector-linux-amd64.tar.gz` |
| **Linux** | ARM64 | `pg-collector-linux-arm64.tar.gz` |
| **macOS** | Intel (x86_64) | `pg-collector-darwin-amd64.tar.gz` |
| **macOS** | Apple Silicon | `pg-collector-darwin-arm64.tar.gz` |
| **Windows** | x86_64 | `pg-collector-windows-amd64.zip` |

### Verify Download

Each release includes a `checksums.txt` file. After downloading:

```bash
sha256sum -c checksums.txt --ignore-missing
```

---

## Choose Your Plan

**Start small, scale as you grow.** All plans include predictive analytics and alerting.

| | **Starter** | **Pro** | **Enterprise** |
|---|:---:|:---:|:---:|
| **Databases** | 1 | Up to 10 | Unlimited |
| **Insight Latency** | Daily digest | 5-minute alerts | Real-time (<1 min) |
| **Statement Analytics** | Top 50 queries | Top 500 queries | Unlimited |
| **Data Retention** | 7 days | 30 days | 90 days |
| **Query Masking** | Basic | Full | Custom rules |
| **Support** | Community | Email | Priority + SLA |

**Ready to get started?** [Book a demo](mailto:sales@burnsideproject.ai) or [try the free evaluation](#demo-mode-quick-evaluation).

---

## AI-Powered Prediction

**The intelligence behind the insights.** Our reasoning engine transforms raw database signals into predictions you can act on.

### How AI Prediction Works

```
       EDGE AGENT                   CLOUD PIPELINE                                    ACTION
    ┌───────────┐             ┌─────────────────────────────────────┐             ┌───────────┐
    │ pg_stat_  │             │         AWS + GCP Infrastructure    │             │  Slack/   │
    │ activity  │────────────▶│  Feature Store ─▶ Claude 3.5 Haiku  │────────────▶│ PagerDuty │
    │ database  │   Signals   │         (AI Classification)         │ Predictions │  Email    │
    │ statements│             │                                     │             │           │
    └───────────┘             └─────────────────────────────────────┘             └───────────┘
    PG Collector                        Burnside Cloud
```

### What the AI Predicts

| Prediction Type | What It Detects | Lead Time |
|-----------------|-----------------|-----------|
| **Connection Exhaustion** | Pool approaching limits based on growth patterns | 15-30 min |
| **Replication Lag Spike** | Replica falling behind due to write surge | 5-10 min |
| **Lock Contention** | Blocking chains forming from concurrent transactions | Real-time |
| **Cache Pressure** | Buffer cache hit ratio degrading | 10-15 min |
| **Vacuum Emergency** | Tables approaching transaction wraparound | Hours/Days |
| **Query Degradation** | Execution plans changing, slow query emergence | Minutes |

### AI Output Examples

**Prediction Alert:**
```json
{
  "severity": "warning",
  "prediction": "Connection pool exhaustion in ~20 minutes",
  "confidence": 0.87,
  "evidence": [
    "Connection count increased 40% in last hour",
    "Current: 85/100 connections",
    "Growth rate: 2.3 connections/minute"
  ],
  "recommended_actions": [
    "Scale connection pool to 150",
    "Enable PgBouncer connection pooling",
    "Review application connection lifecycle"
  ]
}
```

### AI Capabilities by Tier

| Capability | Starter | Pro | Enterprise |
|------------|:-------:|:---:|:----------:|
| Pattern Detection | Daily | 5-min | Real-time |
| Anomaly Alerts | Basic | Advanced | Custom ML |
| Root Cause Analysis | - | AI-assisted | Full AI |
| Predictive Maintenance | - | Standard | Custom |
| Natural Language Insights | Summary | Detailed | Interactive |

---

## Features

### What We Capture

| Category | What You Learn | How Fast |
|----------|----------------|----------|
| **Activity** | Which queries are running, waiting, or blocked | Real-time |
| **Performance** | Slow queries, cache misses, I/O bottlenecks | Continuous |
| **Replication** | Lag alerts before replicas fall behind | Real-time |
| **Storage** | Table bloat and growth trends | Periodic |
| **Background** | Vacuum health and checkpoint pressure | Periodic |

### Built for Production

| Guarantee | What It Means |
|-----------|---------------|
| **Memory Safe** | Configurable ceiling with automatic management—never runaway |
| **Network Resilient** | Local buffering survives outages—zero data loss |
| **Minimal Footprint** | Max 2 PostgreSQL connections, timeout-protected queries |
| **Secure by Default** | mTLS or IAM auth—no passwords in config files |

### Connect Your Way

| Method | Best For | Guide |
|--------|----------|-------|
| **mTLS Certificates** | Self-managed PostgreSQL (most secure) | [Security Guide](docs/security.md) |
| **AWS IAM** | RDS, Aurora (passwordless) | [AWS Setup](docs/aws-setup.md) |
| **GCP IAM** | Cloud SQL (passwordless) | [GCP Setup](docs/gcp-setup.md) |

---

## Quick Configuration

You configure your database connection. Metrics delivery is handled automatically.

```yaml
# Your credentials (provided during onboarding)
customer_id: "your_customer_id"
database_id: "your_database_id"

# Your PostgreSQL connection
postgres:
  conn_string: "postgres://pgcollector@your-db:5432/postgres?sslmode=verify-full"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key
```

See [Configuration Guide](docs/configuration.md) for all options.

---

## Running as a Service

### Systemd (Linux)

```bash
sudo systemctl enable pg-collector
sudo systemctl start pg-collector
sudo systemctl status pg-collector
```

### Docker

```bash
docker run -d \
  --name pg-collector \
  -v /etc/pg-collector:/etc/pg-collector:ro \
  ghcr.io/burnside-project/pg-collector:latest
```

---

## Health & Monitoring

```bash
# Basic health check
curl http://localhost:8080/health

# Detailed status
curl http://localhost:8080/status

# Prometheus metrics
curl http://localhost:8080/metrics
```

---

## How It Works

**From signals to prediction in under 5 minutes.**

```
         EDGE                                    CLOUD                              ACTION
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Your Database  │────▶│   PG Collector  │────▶│   AWS + GCP     │────▶│   Your Team     │
│   (Signals)     │     │  (Edge Agent)   │     │  Claude Haiku   │     │   (Actions)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │                       │
   Raw pg_stat_*          Feature extraction     AI classification       Act before
     metrics              + secure streaming     + predictions          issues hit users
```

1. **Collect Signals** — PG Collector extracts metrics from pg_stat_* views at the edge
   2. **Stream to Cloud** — Metrics stream securely to AWS + GCP infrastructure
   3. **AI Prediction** — Claude 3.5 Haiku analyzes patterns and predicts issues
   4. **Take Action** — Get alerts with recommended fixes before problems escalate

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Quick Start](docs/quick-start.md) | Get running in 5 minutes |
| [Installation](docs/installation.md) | Detailed installation guide |
| [Configuration](docs/configuration.md) | All configuration options |
| [Security](docs/security.md) | mTLS setup, certificate management |
| [AWS Setup](docs/aws-setup.md) | RDS, Aurora deployment |
| [GCP Setup](docs/gcp-setup.md) | Cloud SQL deployment |
| [Monitoring](docs/monitoring.md) | Health checks, Prometheus metrics |
| [CLI Reference](docs/cli-reference.md) | Command-line options |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |
| [FAQ](docs/faq.md) | Frequently asked questions |

---

## Support

- **Documentation:** [docs/](docs/)
  - **Issues:** [GitHub Issues](https://github.com/burnside-project/pg-collector/issues)
  - **Sales:** [sales@burnsideproject.ai](mailto:sales@burnsideproject.ai)
  - **Support:** [support@burnsideproject.ai](mailto:support@burnsideproject.ai)

---

## License

Copyright © 2024–2025 Burnside Project LLC. All rights reserved.

This software is licensed under the **Burnside Project Community Freeware License v1.1**. This is **not open source software**.

**You may** use this software free of charge for personal, educational, evaluation, and internal business purposes.

**You may not** redistribute, sell, sublicense, or offer this software as a hosted service, SaaS, or component of a commercial product without a separate commercial license.

For commercial licensing inquiries, contact [licensing@burnsideproject.ai](mailto:licensing@burnsideproject.ai).

See [LICENSE](LICENSE) for the complete license text.

---

<p align="center">
  <strong>From Signals to Prediction. Stop reacting. Start predicting.</strong><br>
  <sub>AI-powered database observability by <a href="https://burnsideproject.ai">Burnside Project</a></sub>
</p>
