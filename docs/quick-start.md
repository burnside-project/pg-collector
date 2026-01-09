# Quick Start Guide

**From zero to insights in 5 minutes.**

Get PG Collector running and start collecting metrics immediately.

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

Once PG Collector is running, you're done with setup. Here's what happens automatically:

1. **Metrics flow** — Activity, performance, and health data streams from your database
2. **Analysis runs** — Burnside's predictive engine identifies patterns and anomalies
3. **Insights arrive** — Get alerts before problems impact your users

**That's it.** No dashboards to configure, no queries to write. We handle the analytics so you can focus on your application.

---

## Demo Mode (Quick Evaluation)

**Try it now.** Get started in 3 steps—no certificates, no signup, no credit card.

### Step 1: Download and Extract

```bash
# Linux (amd64)
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64-demo.tar.gz
tar -xzf pg-collector-linux-amd64-demo.tar.gz

# macOS Apple Silicon
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-arm64-demo.tar.gz
tar -xzf pg-collector-darwin-arm64-demo.tar.gz
```

The tarball contains:
- `pg-collector-demo` - the binary
- `demo-config.yaml` - configuration template
- `README.txt` - quick reference

### Step 2: Edit Configuration

Open `demo-config.yaml` and update the connection string with your PostgreSQL credentials:

```yaml
postgres:
  # Change this line to match your database:
  conn_string: "postgres://USER:PASSWORD@HOST:PORT/DATABASE?sslmode=disable"
  auth_method: password
```

**Examples:**

| Setup | Connection String |
|-------|------------------|
| Local PostgreSQL | `postgres://postgres:mypass@localhost:5432/postgres?sslmode=disable` |
| Docker container | `postgres://postgres:mypass@172.17.0.1:5432/postgres?sslmode=disable` |
| Remote server | `postgres://myuser:mypass@db.example.com:5432/mydb?sslmode=require` |

**Note:** Your PostgreSQL user needs the `pg_monitor` role for full metrics:
```sql
GRANT pg_monitor TO your_user;
```

### Step 3: Run

```bash
./pg-collector-demo --config demo-config.yaml
```

**That's it!** Metrics stream to `./output/` as JSONL files. You're now collecting PostgreSQL insights.

```bash
# See what's being collected
ls ./output/
# activity/  database/  statements/

# View real-time metrics
tail -f ./output/activity/*.jsonl

# Check health
curl http://localhost:8080/health
```

**Like what you see?** [Book a demo](mailto:sales@burnsideproject.ai) to unlock predictive analytics and real-time alerting.

### Troubleshooting

| Error | Solution |
|-------|----------|
| `password authentication failed` | Check username/password in conn_string |
| `no pg_hba.conf entry` | Add `host all all 127.0.0.1/32 md5` to pg_hba.conf |
| `connection refused` | Verify PostgreSQL is running: `pg_isready` |
| `SSL required` | Add `?sslmode=disable` to connection string |

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

We're here for you:

- [Troubleshooting Guide](troubleshooting.md) — Common issues and solutions
- [GitHub Issues](https://github.com/burnside-project/pg-collector/issues) — Bug reports and feature requests
- [support@burnsideproject.ai](mailto:support@burnsideproject.ai) — Direct support from our team
