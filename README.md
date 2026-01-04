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
- **Zero Impact** - Designed to never affect database performance (2 connection limit, query timeouts, circuit breakers)
- **Never Lose Data** - Resilient buffering with memory and disk overflow protection
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

### Linux (amd64)

```bash
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64.tar.gz
tar -xzf pg-collector-linux-amd64.tar.gz
sudo mv pg-collector /usr/local/bin/
sudo chmod +x /usr/local/bin/pg-collector
```

### macOS (Apple Silicon)

```bash
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-arm64.tar.gz
tar -xzf pg-collector-darwin-arm64.tar.gz
sudo mv pg-collector /usr/local/bin/
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-windows-amd64.zip" -OutFile "pg-collector.zip"
Expand-Archive -Path "pg-collector.zip" -DestinationPath "C:\Program Files\pg-collector"
```

### Verify Download

```bash
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/checksums.txt
sha256sum -c checksums.txt --ignore-missing
```

---

## Features

### Metrics Collected

| Category | Metrics | Sampling |
|----------|---------|----------|
| **Activity** | Active sessions, wait events, query states | 1 second |
| **Performance** | Query statistics, I/O patterns, cache hits | 30 seconds |
| **Replication** | Lag, slot status, WAL positions | 1 second |
| **Storage** | Table/index sizes, bloat, dead tuples | 30 seconds |
| **Background** | Vacuum progress, checkpoint stats | 10 seconds |

### Resource Guarantees

- **Memory:** 50MB ceiling (configurable)
- **Disk:** 500MB buffer limit (configurable)
- **Connections:** Maximum 2 PostgreSQL connections
- **Query Timeout:** 5 seconds (never blocks)

### Authentication Methods

| Method | Use Case | Documentation |
|--------|----------|---------------|
| **mTLS** | Self-managed PostgreSQL (recommended) | [Security Guide](docs/security.md) |
| **AWS IAM** | Amazon RDS, Aurora | [AWS Setup](docs/aws-setup.md) |
| **GCP IAM** | Google Cloud SQL | [GCP Setup](docs/gcp-setup.md) |

---

## Configuration

### Quick Setup

```bash
# Copy example config
sudo mkdir -p /etc/pg-collector
sudo cp /etc/pg-collector/config.yaml.example /etc/pg-collector/config.yaml

# Edit with your settings
sudo vi /etc/pg-collector/config.yaml
```

### Example Configuration

```yaml
customer_id: "cust_your_id"
database_id: "db_prod_01"
tenant_tier: "starter"
output_mode: "s3_only"

postgres:
  conn_string: "postgres://pgcollector@your-db:5432/postgres?sslmode=verify-full"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key

s3:
  enabled: true
  region: "us-east-1"
  bucket: "your-metrics-bucket"
  batch_interval: 5m
  format: "parquet"
```

See [Configuration Guide](docs/configuration.md) for all options.

---

## Running as a Service

### Systemd (Linux)

```bash
sudo tee /etc/systemd/system/pg-collector.service << 'EOF'
[Unit]
Description=PostgreSQL Metrics Collector
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pg-collector
Group=pg-collector
ExecStart=/usr/local/bin/pg-collector --config /etc/pg-collector/config.yaml
Restart=always
RestartSec=5
LimitNOFILE=65536

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/pg-collector

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pg-collector
sudo systemctl start pg-collector
```

### Docker

```bash
docker run -d \
  --name pg-collector \
  -v /etc/pg-collector:/etc/pg-collector:ro \
  -v /var/lib/pg-collector:/var/lib/pg-collector \
  ghcr.io/burnside-project/pg-collector:latest \
  --config /etc/pg-collector/config.yaml
```

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Quick Start](docs/quick-start.md) | Get running in 5 minutes |
| [Configuration](docs/configuration.md) | All configuration options |
| [Security](docs/security.md) | mTLS setup, certificate management |
| [AWS Setup](docs/aws-setup.md) | RDS, Aurora deployment guide |
| [GCP Setup](docs/gcp-setup.md) | Cloud SQL deployment guide |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |

---

## Health & Monitoring

### Health Endpoints

```bash
# Basic health check
curl http://localhost:8080/health

# Detailed status
curl http://localhost:8080/status

# Prometheus metrics
curl http://localhost:8080/metrics
```

### Health Response

```json
{
  "status": "healthy",
  "postgres": "connected",
  "output": "ok",
  "buffer": {
    "memory_used": 1024,
    "disk_used": 0
  }
}
```

---

## Support

- **Documentation:** [docs/](docs/)
- **Issues:** [GitHub Issues](https://github.com/burnside-project/pg-collector/issues)
- **Email:** support@burnsideproject.ai
- **Commercial Support:** enterprise@burnsideproject.ai

---

## License

Copyright 2024-2025 Burnside Project, Inc.

Licensed under the Apache License, Version 2.0 with Additional Terms. See [LICENSE](LICENSE) for the complete license text including warranty disclaimers and liability limitations.

**IMPORTANT:** This software is provided "AS IS" without warranty of any kind. See the LICENSE file for complete disclaimer of warranties and limitation of liability.

---

<p align="center">
  <sub>Built with care for database reliability</sub>
</p>
