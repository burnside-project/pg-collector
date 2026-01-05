# Quick Start Guide

Get PG Collector running in 5 minutes.

## Prerequisites

- PostgreSQL 12 or later
- Linux, macOS, or Windows
- Network access to your PostgreSQL instance

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

Connect to your PostgreSQL database:

```sql
-- Create monitoring user
CREATE USER pgcollector;

-- Grant monitoring permissions
GRANT pg_monitor TO pgcollector;
```

## Step 3: Configure

Create the configuration file:

```bash
sudo mkdir -p /etc/pg-collector
sudo vi /etc/pg-collector/config.yaml
```

Minimal configuration:

```yaml
customer_id: "your_customer_id"
database_id: "your_database_id"

postgres:
  conn_string: "postgres://pgcollector@localhost:5432/postgres?sslmode=verify-full"
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

## Step 4: Set Up Certificates

See [Security Guide](security.md) for detailed mTLS setup.

```bash
sudo mkdir -p /etc/pg-collector/certs

# Copy your certificates
sudo cp ca.crt client.crt client.key /etc/pg-collector/certs/

# Set permissions
sudo chmod 600 /etc/pg-collector/certs/*.key
sudo chmod 644 /etc/pg-collector/certs/*.crt
```

## Step 5: Test Connection

```bash
pg-collector --config /etc/pg-collector/config.yaml --test
```

Expected output:
```
Testing PostgreSQL connection... OK
Testing output destination... OK
All tests passed
```

## Step 6: Run

### Foreground (testing)

```bash
pg-collector --config /etc/pg-collector/config.yaml
```

### As a Service (production)

```bash
sudo systemctl enable pg-collector
sudo systemctl start pg-collector
```

## Step 7: Verify

Check health:

```bash
curl http://localhost:8080/health
```

Check logs:

```bash
sudo journalctl -u pg-collector -f
```

## Next Steps

- [Configuration Guide](configuration.md) - All options
- [Security Guide](security.md) - Certificate setup
- [Troubleshooting](troubleshooting.md) - Common issues

## Need Help?

- [Troubleshooting Guide](troubleshooting.md)
- [GitHub Issues](https://github.com/burnside-project/pg-collector/issues)
- Email: support@burnsideproject.ai
