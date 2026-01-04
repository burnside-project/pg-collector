# Quick Start Guide

Get PG Collector running in 5 minutes.

## Prerequisites

- PostgreSQL 12 or later
- Linux, macOS, or Windows
- Network access to your PostgreSQL instance
- (Optional) S3 bucket for metrics storage

## Step 1: Install

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/burnside-project/pg-collector/main/scripts/install.sh | sudo bash
```

### Manual Install

```bash
# Linux (amd64)
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64.tar.gz
tar -xzf pg-collector-linux-amd64.tar.gz
sudo mv pg-collector /usr/local/bin/
```

## Step 2: Create PostgreSQL User

Connect to your PostgreSQL database and create a monitoring user:

```sql
-- Create the user (no password - will use certificate auth)
CREATE USER pgcollector;

-- Grant necessary permissions
GRANT pg_monitor TO pgcollector;
GRANT USAGE ON SCHEMA public TO pgcollector;

-- For pg_stat_statements (if using)
GRANT EXECUTE ON FUNCTION pg_stat_statements_reset(oid, oid, bigint) TO pgcollector;
```

## Step 3: Configure

Create the configuration file:

```bash
sudo mkdir -p /etc/pg-collector
sudo tee /etc/pg-collector/config.yaml << 'EOF'
customer_id: "your_customer_id"
database_id: "your_database_id"
tenant_tier: "starter"
output_mode: "s3_only"

postgres:
  conn_string: "postgres://pgcollector@localhost:5432/postgres?sslmode=verify-full"
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
EOF
```

## Step 4: Set Up Certificates

See [Security Guide](security.md) for detailed mTLS setup. Quick version:

```bash
sudo mkdir -p /etc/pg-collector/certs

# Copy your certificates
sudo cp ca.crt /etc/pg-collector/certs/
sudo cp client.crt /etc/pg-collector/certs/
sudo cp client.key /etc/pg-collector/certs/

# Set permissions
sudo chmod 600 /etc/pg-collector/certs/*.key
```

## Step 5: Test Connection

```bash
pg-collector --config /etc/pg-collector/config.yaml --test
```

Expected output:
```
[INFO] Testing PostgreSQL connection...
[INFO] Connected successfully
[INFO] Testing S3 connection...
[INFO] S3 bucket accessible
[INFO] All tests passed
```

## Step 6: Run

### Foreground (testing)

```bash
pg-collector --config /etc/pg-collector/config.yaml
```

### Background (systemd)

```bash
sudo systemctl enable pg-collector
sudo systemctl start pg-collector
sudo systemctl status pg-collector
```

## Step 7: Verify

Check the health endpoint:

```bash
curl http://localhost:8080/health
```

Check logs:

```bash
sudo journalctl -u pg-collector -f
```

## Next Steps

- [Configuration Guide](configuration.md) - All configuration options
- [Security Guide](security.md) - Certificate setup and hardening
- [Troubleshooting](troubleshooting.md) - Common issues

## Having Issues?

- Check [Troubleshooting Guide](troubleshooting.md)
- Open an [issue](https://github.com/burnside-project/pg-collector/issues)
- Contact support@burnsideproject.ai
