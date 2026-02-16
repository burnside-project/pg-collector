# Subscription Plans

Compare PG Collector plans and choose the right one for your team.

---

## Overview

PG Collector offers subscription tiers designed to scale with your needs:

| Tier | Target Users |
|------|-------------|
| **Demo** | Evaluation and proof-of-concept |
| **Starter** | Individual developers, single database |
| **Pro** | Growing teams, multiple databases |
| **Business** | Medium organizations, advanced monitoring |
| **Enterprise** | Large organizations, maximum performance |

---

## Feature Comparison

| Feature | Demo | Starter | Pro | Business | Enterprise |
|---------|:----:|:-------:|:---:|:--------:|:----------:|
| **Databases** | 1 | 1 | Multiple | Many | Unlimited |
| **Sampling frequency** | Basic | Standard | Fast | Faster | Real-time |
| **Metric samplers** | Core (3) | Core | Extended | Full | All |
| **Output** | Local only | Cloud | Cloud | Cloud | Cloud + Custom |
| **Data retention** | Local files | Standard | Extended | Long-term | Custom |
| **AI insights** | — | Summary | Detailed | Predictive | Interactive |
| **Support** | Community | Email | Priority Email | Business Hours | 24/7 |

---

## Sampler Availability by Plan

PG Collector includes 12 PostgreSQL metric samplers organized into two groups.

**Core samplers** cover essential database health. **Extended samplers** provide deeper insight for advanced monitoring and prediction.

| Sampler | Description | Demo | Starter | Pro | Business | Enterprise |
|---------|-------------|:----:|:-------:|:---:|:--------:|:----------:|
| **activity** | Active sessions and wait events | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| **database** | Transaction rates, cache hits, deadlocks | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| **statements** | Query performance metrics | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| **bgwriter** | Checkpoint and buffer write stats | | | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| **replication** | Replication lag and sync state | | | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| **vacuum** | Dead tuples, vacuum progress, bloat risk | | | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| **locks** | Lock contention and blocking chains | | | | :white_check_mark: | :white_check_mark: |
| **wal** | WAL generation and archiver stats | | | | :white_check_mark: | :white_check_mark: |
| **slots** | Replication slot lag | | | | :white_check_mark: | :white_check_mark: |
| **wal_receiver** | Standby receive lag | | | | | :white_check_mark: |
| **statio** | Table and index I/O statistics | | | | | :white_check_mark: |
| **bloat** | Table and index bloat estimation | | | | | :white_check_mark: |

---

## Security Features by Plan

| Feature | Demo | Starter | Pro | Business | Enterprise |
|---------|:----:|:-------:|:---:|:--------:|:----------:|
| **Basic query masking** | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| **Custom masking rules** | | | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| **PII detection** | Basic | Basic | Basic | Full | Full |
| **Audit logging** | | | | :white_check_mark: | :white_check_mark: |
| **SOC 2 compliance** | | | | :white_check_mark: | :white_check_mark: |
| **HIPAA support** | | | | | :white_check_mark: |

---

!!! tip "Demo Tier — Free for Evaluation"

    The Demo tier is completely free and requires no subscription. Use it to evaluate PG Collector locally with a single database and local file output. When you're ready for production, upgrade to a paid plan for cloud streaming, more databases, and AI-powered predictions.

---

## Choosing a Plan

| If you need... | Recommended plan |
|----------------|-----------------|
| Local evaluation or POC | **Demo** |
| Single production database with basic monitoring | **Starter** |
| Multiple databases with replication and vacuum monitoring | **Pro** |
| Organization-wide monitoring with lock analysis and compliance | **Business** |
| Unlimited databases, real-time sampling, full security features | **Enterprise** |

---

## Upgrading and Downgrading

- **Upgrades** take effect immediately — new features and limits are applied right away
- **Downgrades** take effect immediately — limits are reduced to the new plan
- **Data retention** — historical data beyond the new plan's limit is archived, not deleted
- **Excess databases** — if you have more databases than the new plan allows, excess databases are paused with a warning in logs

To change your plan, visit the [Burnside Dashboard](https://dashboard.burnsideproject.ai) and navigate to your subscription settings.

---

## Related Documentation

- [Configuration Guide](configuration.md) — Set up output modes and sampling
- [Device Activation](activation.md) — How collectors activate and manage state
- [Architecture Overview](architecture.md) — How PG Collector works
- [Quick Start](quick-start.md) — Get started in 5 minutes
