# PG Collector

**From Signals to Prediction** — Lightweight Agent for AI-Powered PostgreSQL Intelligence

---

## Overview

**Stop reacting to database issues—start predicting them.**

PG Collector is a lightweight metrics agent that extracts PostgreSQL telemetry and delivers it to configurable destinations — locally for evaluation, or streamed to our cloud platform where AI analyzes patterns and predicts issues before they impact your users.

**Single binary. Zero dependencies. 5-minute setup.**

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ PostgreSQL   │ ───▶ │ PG Collector │ ───▶ │   Burnside   │ ───▶ │ Predictions  │
│  Database    │      │   (Agent)    │      │    Cloud     │      │  & Alerts    │
└──────────────┘      └──────────────┘      └──────────────┘      └──────────────┘
```

## Two Editions

### Demo Edition (Free)

- Single binary, zero external dependencies
- Runs locally; all output stays on your machine
- Core PostgreSQL samplers: activity, database, and statements
- Export snapshots to your favorite LLM (ChatGPT, Claude, etc.) for instant analysis
- Perfect for evaluation, learning, and local development

### Commercial Edition (Subscription)

Everything in Demo, plus:

- Up to 12 PostgreSQL metric samplers
- AI-powered health reports with prescriptions
- Real-time streaming to Burnside Cloud
- Interactive health dashboard with configuration audit
- Multi-database monitoring, PII detection, audit logging
- mTLS, AWS IAM, GCP IAM authentication

---

## Quick Install

=== "Linux (x86_64)"

    ```bash
    curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64.tar.gz
    tar -xzf pg-collector-linux-amd64.tar.gz
    sudo mv pg-collector /usr/local/bin/
    ```

=== "Linux (ARM64)"

    ```bash
    curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-arm64.tar.gz
    tar -xzf pg-collector-linux-arm64.tar.gz
    sudo mv pg-collector /usr/local/bin/
    ```

=== "macOS (Apple Silicon)"

    ```bash
    curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-arm64.tar.gz
    tar -xzf pg-collector-darwin-arm64.tar.gz
    sudo mv pg-collector /usr/local/bin/
    ```

=== "macOS (Intel)"

    ```bash
    curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-amd64.tar.gz
    tar -xzf pg-collector-darwin-amd64.tar.gz
    sudo mv pg-collector /usr/local/bin/
    ```

---

## Choose Your Plan

**Start small, scale as you grow.** All commercial plans include predictive analytics and alerting.

| | **Demo** | **Starter** | **Pro** | **Business** | **Enterprise** |
|---|:---:|:-----------:|:---:|:---:|:---:|
| **Databases** | 1 | 1 | Multiple | Many | Unlimited |
| **Sampling frequency** | Basic | Standard | Fast | Faster | Real-time |
| **Metric samplers** | Core (3) | Core | Extended | Full | All (12) |
| **AI insights** | — | Summary | Detailed | Predictive | Interactive |
| **Support** | Community | Email | Priority Email | Business Hours | 24/7 |

See [Subscription Plans](plans.md) for the full comparison including security features and sampler availability.

[Book a Demo](mailto:sales@burnsideproject.ai){ .md-button .md-button--primary }
[View Documentation](quick-start.md){ .md-button }

---

## AI-Powered Prediction

**The intelligence behind the insights.** Our AI transforms raw database metrics into predictions you can act on.

### What the AI Predicts

| Prediction Type | What It Detects |
|-----------------|-----------------|
| **Connection Exhaustion** | Pool approaching limits based on growth patterns |
| **Replication Lag Spike** | Replica falling behind due to write surge |
| **Lock Contention** | Blocking chains forming from concurrent transactions |
| **Cache Pressure** | Buffer cache hit ratio degrading |
| **Vacuum Emergency** | Tables approaching transaction wraparound |
| **Query Degradation** | Execution plans changing, slow query emergence |

### How It Works

The AI engine continuously analyzes your PostgreSQL metrics, detects patterns, and delivers:

- **Severity-rated alerts** — Know what's critical vs. informational
- **Confidence scoring** — Understand how certain the prediction is
- **Evidence-based reasoning** — See the data points driving the alert
- **Recommended actions** — Get specific, actionable fix suggestions

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

Learn more: [Architecture Overview](architecture.md) | [Device Activation](activation.md)

### Connect Your Way

| Method | Best For | Guide |
|--------|----------|-------|
| **mTLS Certificates** | Self-managed PostgreSQL (most secure) | [Security Guide](security.md) |
| **AWS IAM** | RDS, Aurora (passwordless) | [AWS Setup](aws-setup.md) |
| **GCP IAM** | Cloud SQL (passwordless) | [GCP Setup](gcp-setup.md) |

---

## Quick Configuration

```yaml
# API key from admin console (activates automatically on first run)
api_key: "${API_KEY}"

# Your PostgreSQL databases
databases:
  - name: Production
    postgres:
      conn_string: "postgres://pgcollector@your-db:5432/postgres?sslmode=verify-full"
      auth_method: cert
      tls:
        mode: verify-full
        ca_file: /etc/pg-collector/certs/ca.crt
        cert_file: /etc/pg-collector/certs/client.crt
        key_file: /etc/pg-collector/certs/client.key
```

See [Configuration Guide](configuration.md) for all options.

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

## Support

- **Documentation:** Browse this site
- **Issues:** [GitHub Issues](https://github.com/burnside-project/pg-collector/issues)
- **Sales:** [sales@burnsideproject.ai](mailto:sales@burnsideproject.ai)
- **Support:** [support@burnsideproject.ai](mailto:support@burnsideproject.ai)

---

<p align="center">
  <strong>From Signals to Prediction. Stop reacting. Start predicting.</strong><br>
  <sub>AI-powered database observability by <a href="https://burnsideproject.ai">Burnside Project</a></sub>
</p>
