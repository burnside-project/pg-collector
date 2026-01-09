# Quick Start Guide

Get PG Collector running in 5 minutes.

## Prerequisites

- PostgreSQL 12 or later
- Linux, macOS, or Windows
- Network access to your PostgreSQL instance
- Customer credentials from Burnside (customer_id)

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
# Your credentials (provided during onboarding)
customer_id: "your_customer_id"
database_id: "your_database_id"

# Your PostgreSQL connection
postgres:
  conn_string: "postgres://pgcollector@localhost:5432/postgres?sslmode=verify-full"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key
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
Testing platform connectivity... OK
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

Expected response:
```json
{
  "status": "healthy",
  "postgres": "connected"
}
```

Check logs:

```bash
sudo journalctl -u pg-collector -f
```

## What Happens Next

Once PG Collector is running:

1. **Metrics are collected** from your PostgreSQL database
2. **Data is securely transmitted** to the Burnside platform
3. **Analytics are available** in your Burnside dashboard

You don't need to configure where data goes - that's handled automatically based on your subscription.

---

## Demo Mode (Quick Evaluation)

For quick evaluation without certificate setup, use the demo build.

### Step 1: Download Demo Build

```bash
# Linux (amd64)
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64-demo.tar.gz
tar -xzf pg-collector-linux-amd64-demo.tar.gz

# Linux (arm64)
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-arm64-demo.tar.gz
tar -xzf pg-collector-linux-arm64-demo.tar.gz

# macOS Intel
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-amd64-demo.tar.gz
tar -xzf pg-collector-darwin-amd64-demo.tar.gz

# macOS Apple Silicon
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-arm64-demo.tar.gz
tar -xzf pg-collector-darwin-arm64-demo.tar.gz
```

Verify the download:

```bash
./pg-collector-demo --version
# Output: pg-collector vX.X.X (commit: ..., built: ..., mode: demo)
```

### Step 2: Create PostgreSQL User

Connect to your PostgreSQL database as a superuser:

```bash
# Local PostgreSQL
psql -U postgres

# macOS Homebrew PostgreSQL
psql postgres

# Docker PostgreSQL
docker exec -it <container> psql -U postgres
```

Create a monitoring user with password:

```sql
-- Create user with password (for demo mode)
CREATE USER pgcollector WITH PASSWORD 'collector_password';

-- Grant monitoring permissions
GRANT pg_monitor TO pgcollector;

-- Verify the user was created
\du pgcollector
```

### Step 3: Test Database Connection

Before running the collector, verify you can connect:

```bash
# Test connection with password
psql "postgres://pgcollector:collector_password@localhost:5432/postgres?sslmode=disable"

# You should see: postgres=>
# Type \q to exit
```

**Common connection issues:**

| Error | Solution |
|-------|----------|
| `FATAL: password authentication failed` | Check password in connection string |
| `FATAL: no pg_hba.conf entry` | Add `host all pgcollector 127.0.0.1/32 md5` to pg_hba.conf |
| `connection refused` | Check PostgreSQL is running on port 5432 |
| `SSL required` | Add `?sslmode=disable` to connection string for local testing |

### Step 4: Create Configuration File

Create `demo-config.yaml`:

```yaml
# demo-config.yaml
customer_id: "demo"
database_id: "my_local_db"

output_mode: local_only

postgres:
  # Format: postgres://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=disable
  conn_string: "postgres://pgcollector:collector_password@localhost:5432/postgres?sslmode=disable"
  auth_method: password  # Only allowed in demo builds

local:
  enabled: true
  path: ./output
  format: jsonl
  split_by_metric_type: true
```

**Connection string format:**

```
postgres://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=MODE

Examples:
  localhost:        postgres://pgcollector:pass@localhost:5432/postgres?sslmode=disable
  Docker (Linux):   postgres://pgcollector:pass@172.17.0.1:5432/postgres?sslmode=disable
  Docker (macOS):   postgres://pgcollector:pass@docker.for.mac.localhost:5432/postgres?sslmode=disable
  Remote:           postgres://pgcollector:pass@db.example.com:5432/mydb?sslmode=require
```

### Step 5: Run Demo

```bash
./pg-collector-demo --config demo-config.yaml
```

You should see output like:

```json
{"level":"info","msg":"starting pg-collector","version":"v0.2.0","mode":"demo"}
{"level":"info","msg":"connected to PostgreSQL databases","database_count":1}
{"level":"info","msg":"created local filesystem producer","path":"./output"}
{"level":"info","msg":"pg-collector started successfully"}
```

Metrics are written to the `./output` directory in JSONL format:

```bash
ls ./output/
# activity/  database/  bgwriter/  ...

# View collected metrics
head ./output/activity/*.jsonl
```

### Demo Limitations

| Feature | Demo | Production |
|---------|------|------------|
| Password auth | Allowed | Rejected |
| mTLS/IAM auth | Supported | Required |
| Local output | Yes | Yes |
| S3 output | Yes | Yes |
| Platform output | No | Yes |

For production, see [Security Guide](security.md) for certificate setup.

---

## Next Steps

- [Configuration Guide](configuration.md) - All options
- [Security Guide](security.md) - Certificate setup
- [Troubleshooting](troubleshooting.md) - Common issues

## Need Help?

- [Troubleshooting Guide](troubleshooting.md)
- [GitHub Issues](https://github.com/burnside-project/pg-collector/issues)
- Email: support@burnsideproject.ai
