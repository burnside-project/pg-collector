<p align="center">
  <h1 align="center">PG Collector</h1>
  <p align="center">
    <strong>Know what's happening. Predict what's next.</strong>
  </p>
  <p align="center">
    <em>Real-time PostgreSQL observability for confident decision-making</em>
  </p>
</p>

<p align="center">
  <a href="https://github.com/burnside-project/pg-collector/releases"><img src="https://img.shields.io/github/v/release/burnside-project/pg-collector?style=flat-square" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square" alt="License"></a>
  <a href="https://github.com/burnside-project/pg-collector/releases"><img src="https://img.shields.io/github/downloads/burnside-project/pg-collector/total?style=flat-square" alt="Downloads"></a>
</p>

<p align="center">
  <a href="#quick-install">Install</a> |
  <a href="#features">Features</a> |
  <a href="#subscription-tiers">Tiers</a> |
  <a href="docs/quick-start.md">Quick Start</a> |
  <a href="docs/configuration.md">Configuration</a> |
  <a href="docs/security.md">Security</a>
</p>

---

## Overview

Stop reacting to database issues—start predicting them. PG Collector transforms raw PostgreSQL metrics into actionable insights, giving your team the confidence to act before problems become outages.

**A single binary. Zero dependencies. 5-minute setup.**

**Why Teams Choose PG Collector:**

| | |
|---|---|
| **Act Before Problems Hit** | Real-time metrics feed predictive analytics that identify issues before they impact users |
| **Zero Database Impact** | Designed from the ground up to never affect your database performance |
| **No DBA Required** | Clear insights without needing to interpret pg_stat views yourself |
| **Works Everywhere** | RDS, Aurora, Cloud SQL, or self-managed—we've got you covered |
| **Never Lose Data** | Resilient buffering survives network hiccups without dropping metrics |

---

## Quick Install

### One-Line Install (Linux/macOS)

```bash
curl -sSL https://raw.githubusercontent.com/burnside-project/pg-collector/main/scripts/install.sh | sudo bash
```

### Specific Version

```bash
curl -sSL https://raw.githubusercontent.com/burnside-project/pg-collector/main/scripts/install.sh | sudo bash -s -- --version v1.0.0
```

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

**From install to insight in under 5 minutes.**

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Your Database  │────▶│   PG Collector  │────▶│    Burnside     │────▶│   Your Team     │
│   (PostgreSQL)  │     │   (Your Host)   │     │    Platform     │     │   (Insights)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │                       │
    You manage            5-min setup             We analyze           You decide
   the database           one config file      predict & alert      with confidence
```

1. **Install** — One command, runs anywhere
2. **Configure** — Point to your database, we handle the rest
3. **Insights** — Predictive analytics identify issues before they escalate

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

Copyright 2024-2025 Burnside Project, Inc.

Licensed under the Apache License, Version 2.0 with Additional Terms. See [LICENSE](LICENSE) for the complete license text including warranty disclaimers and liability limitations.

---

<p align="center">
  <strong>Stop reacting. Start predicting.</strong><br>
  <sub>Built by the team at <a href="https://burnsideproject.ai">Burnside Project</a></sub>
</p>
