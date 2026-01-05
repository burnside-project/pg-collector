<p align="center">
  <h1 align="center">PG Collector</h1>
  <p align="center">
    <strong>PostgreSQL Metrics Collector for Predictive Analytics</strong>
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
  <a href="docs/quick-start.md">Quick Start</a> |
  <a href="docs/configuration.md">Configuration</a> |
  <a href="docs/security.md">Security</a>
</p>

---

## Overview

PG Collector is a lightweight, high-performance PostgreSQL metrics collector designed for predictive database analytics. It runs as a single binary with zero external dependencies, collecting comprehensive database metrics and streaming them to your analytics platform.

**Key Benefits:**
- **Zero Impact** - Designed to never affect database performance
- **Never Lose Data** - Resilient buffering protects against network interruptions
- **Secure by Default** - mTLS authentication, no passwords stored
- **Cloud Native** - Works with RDS, Aurora, Cloud SQL, and self-managed PostgreSQL

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

| Platform | Architecture | Download |
|----------|--------------|----------|
| **Linux** | x86_64 (amd64) | [pg-collector-linux-amd64.tar.gz](https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64.tar.gz) |
| **Linux** | ARM64 | [pg-collector-linux-arm64.tar.gz](https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-arm64.tar.gz) |
| **macOS** | Intel (x86_64) | [pg-collector-darwin-amd64.tar.gz](https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-amd64.tar.gz) |
| **macOS** | Apple Silicon | [pg-collector-darwin-arm64.tar.gz](https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-arm64.tar.gz) |
| **Windows** | x86_64 | [pg-collector-windows-amd64.zip](https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-windows-amd64.zip) |

### Verify Download

```bash
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/checksums.txt
sha256sum -c checksums.txt --ignore-missing
```

---

## Features

### Metrics Collected

| Category | Description | Frequency |
|----------|-------------|-----------|
| **Activity** | Active sessions, wait events, query states | Real-time |
| **Performance** | Query statistics, I/O patterns, cache efficiency | Periodic |
| **Replication** | Lag, slot status, streaming state | Real-time |
| **Storage** | Table/index sizes, bloat indicators | Periodic |
| **Background** | Vacuum progress, checkpoint activity | Periodic |

### Resource Guarantees

- **Memory:** Configurable ceiling with automatic management
- **Disk:** Local buffering during network interruptions
- **Connections:** Minimal PostgreSQL connection usage
- **Queries:** Timeout protection prevents blocking

### Authentication Methods

| Method | Use Case | Documentation |
|--------|----------|---------------|
| **mTLS** | Self-managed PostgreSQL (recommended) | [Security Guide](docs/security.md) |
| **AWS IAM** | Amazon RDS, Aurora | [AWS Setup](docs/aws-setup.md) |
| **GCP IAM** | Google Cloud SQL | [GCP Setup](docs/gcp-setup.md) |

---

## Quick Configuration

```yaml
customer_id: "your_customer_id"
database_id: "your_database_id"

postgres:
  conn_string: "postgres://pgcollector@your-db:5432/postgres?sslmode=verify-full"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key

output:
  type: s3
  region: "us-east-1"
  bucket: "your-metrics-bucket"
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
- **Email:** support@burnsideproject.ai

---

## License

Copyright 2024-2025 Burnside Project, Inc.

Licensed under the Apache License, Version 2.0 with Additional Terms. See [LICENSE](LICENSE) for the complete license text including warranty disclaimers and liability limitations.

---

<p align="center">
  <sub>Built for database reliability</sub>
</p>
