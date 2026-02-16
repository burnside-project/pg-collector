# Quick Start Guide

Get PG Collector running in 5 minutes.

## Prerequisites

- PostgreSQL 12 or later
- Linux, macOS, or Windows
- API key from the [Burnside Dashboard](https://dashboard.burnsideproject.ai)

---

## Step 1: Install

```bash
# Linux (amd64)
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64.tar.gz
tar -xzf pg-collector-linux-amd64.tar.gz
sudo mv pg-collector /usr/local/bin/
```

## Step 2: Create PostgreSQL User

```sql
-- Create monitoring user
CREATE USER pgcollector;

-- Grant monitoring permissions
GRANT pg_monitor TO pgcollector;
```

## Step 3: Configure

```bash
sudo mkdir -p /etc/pg-collector
sudo vi /etc/pg-collector/config.yaml
```

```yaml
# API key from admin console
api_key: "pgc_pro_abc123..."

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

## Step 4: Set Up Certificates

```bash
sudo mkdir -p /etc/pg-collector/certs
sudo cp ca.crt client.crt client.key /etc/pg-collector/certs/
sudo chmod 600 /etc/pg-collector/certs/*.key
```

See [Security Guide](security.md) for certificate generation.

## Step 5: Validate Configuration

```bash
pg-collector --check-config --config /etc/pg-collector/config.yaml
```

## Step 6: Run

```bash
# First run: auto-activates using api_key from config
pg-collector --config /etc/pg-collector/config.yaml
```

On first run, the collector:
1. Activates with the Burnside platform using your API key
2. Stores device state locally (survives restarts)
3. Begins collecting metrics

## Step 7: Verify

```bash
curl http://localhost:8080/health
```

```json
{
  "status": "ok",
  "components": {
    "postgres": {"status": "ok"}
  }
}
```

---

## Run as Service

```bash
sudo systemctl enable pg-collector
sudo systemctl start pg-collector
sudo journalctl -u pg-collector -f
```

---

## Demo Mode

Quick evaluation without API key or certificates:

### Download Demo Build

```bash
# Linux
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64-demo.tar.gz
tar -xzf pg-collector-linux-amd64-demo.tar.gz

# macOS
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-arm64-demo.tar.gz
tar -xzf pg-collector-darwin-arm64-demo.tar.gz
```

### Demo Configuration

```yaml
# demo-config.yaml
databases:
  - name: local
    postgres:
      conn_string: "postgres://user:pass@localhost:5432/postgres?sslmode=disable"
      auth_method: password  # Only in demo builds

local:
  enabled: true
  path: ./output
  format: jsonl
```

### Run Demo

```bash
./pg-collector-demo --config demo-config.yaml

# View metrics
ls ./output/
tail -f ./output/activity/*.jsonl
```

### Demo Limitations

| Feature | Demo | Production |
|---------|------|------------|
| Password auth | Yes | No |
| API key required | No | Yes |
| Cloud output | No | Yes |
| Local output | Yes | Yes |

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| `device not activated` | Add `api_key` to config file |
| `password authentication failed` | Check credentials in conn_string |
| `connection refused` | Verify PostgreSQL is running: `pg_isready` |
| `certificate verify failed` | Check TLS certificate paths |

---

## Next Steps

- [Configuration Guide](configuration.md) - All options
- [Security Guide](security.md) - Certificate setup
- [Monitoring](monitoring.md) - Health endpoints
