# Configuration Guide

Complete reference for PG Collector configuration.

## Configuration File

Default location: `/etc/pg-collector/config.yaml`

Override with: `pg-collector --config /path/to/config.yaml`

---

## Minimal Configuration

The simplest production configuration — just your API key and a database connection:

```yaml
api_key: "${API_KEY}"

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

Everything else — tier, features, output destination, sampling intervals — is derived automatically from your subscription after [device activation](activation.md).

---

## Full Configuration Reference

```yaml
# =============================================================================
# ACTIVATION (Required for production)
# =============================================================================

# API key from admin console (required)
# On first run, collector activates using this key
api_key: "${API_KEY}"

# =============================================================================
# DATABASES (Required)
# =============================================================================

databases:
  - name: "Production"

    # Optional: Filter which samplers run for this database
    # If omitted, all tier-allowed samplers are enabled
    # samplers: [activity, database, statements, bgwriter, replication, vacuum]

    postgres:
      conn_string: "postgres://pgcollector@your-db:5432/postgres?sslmode=verify-full"
      auth_method: cert
      query_timeout: 5s
      tls:
        mode: verify-full
        ca_file: /etc/pg-collector/certs/ca.crt
        cert_file: /etc/pg-collector/certs/client.crt
        key_file: /etc/pg-collector/certs/client.key

# =============================================================================
# SAMPLING INTERVALS
# =============================================================================

sampling:
  # Enable/disable samplers
  enabled:
    activity: true
    database: true
    statements: true
    bgwriter: true
    replication: true
    vacuum: true
    locks: false       # Extended, disabled by default
    wal: false
    slots: false
    wal_receiver: false
    statio: false
    bloat: false

  # Sampling intervals (plan defaults applied automatically)
  # You can override intervals here, but they will be clamped to your plan's
  # minimum interval. For example, setting activity: 5s on a Starter plan
  # will use the Starter minimum instead.
  activity: 10s
  database: 30s
  statements: 60s

# =============================================================================
# SAMPLER REFERENCE
# =============================================================================
#
# Core (Default enabled):
#   activity    - Active sessions, wait events (pg_stat_activity)
#   database    - Transaction rates, cache hits (pg_stat_database)
#   statements  - Query performance metrics (pg_stat_statements)
#   bgwriter    - Checkpoint and buffer stats (pg_stat_bgwriter)
#   replication - Replication lag and sync state (pg_stat_replication)
#   vacuum      - Dead tuples, vacuum progress (pg_stat_user_tables)
#
# Extended (Default disabled):
#   locks        - Lock contention analysis (pg_locks)
#   wal          - WAL generation stats (pg_stat_wal, PG 14+)
#   slots        - Replication slot lag (pg_replication_slots)
#   wal_receiver - Standby receive lag (pg_stat_wal_receiver)
#   statio       - Table I/O statistics (pg_statio_user_tables)
#   bloat        - Table/index bloat estimation

# =============================================================================
# HTTP ENDPOINTS
# =============================================================================

http:
  address: ":8080"
  read_timeout: 5s
  write_timeout: 10s

# =============================================================================
# LOGGING
# =============================================================================

log:
  level: info      # debug, info, warn, error
  format: json     # json, console

# =============================================================================
# SECURITY
# =============================================================================

security:
  # Query masking: none, basic, full, custom
  query_masking_level: basic

  # PII detection (Business/Enterprise only)
  pii_detection: false

  # Audit logging (Business/Enterprise only)
  audit_logging: false
  audit_log_path: /var/log/pg-collector/audit.log

  # Custom masking patterns (Enterprise only)
  masking_patterns:
    - "password"
    - "secret"
    - "token"
```

---

## Plan-Based Defaults

Features and limits vary by subscription plan. The collector automatically applies the correct defaults based on your plan after [device activation](activation.md).

| Feature | Demo | Starter | Pro | Business | Enterprise |
|---------|:----:|:-------:|:---:|:--------:|:----------:|
| Database limit | 1 | 1 | Multiple | Many | Unlimited |
| Sampling frequency | Basic | Standard | Fast | Faster | Real-time |
| Query masking | Basic | Basic | Custom | Custom | Custom |
| PII detection | Basic | Basic | Basic | Full | Full |
| Audit logging | — | — | — | Yes | Yes |

See [Subscription Plans](plans.md) for the full comparison including sampler availability and security features.

!!! note "Plan Minimums"

    If you set a sampling interval lower than your plan allows, the collector will use the plan minimum instead.

---

## Environment Variables

PG Collector supports environment variable expansion in all configuration values. Use `${VAR}` for required variables and `${VAR:-default}` for optional ones with fallback values.

### Supported Variables

**Authentication:**

| Variable | Description | Default |
|----------|-------------|---------|
| `API_KEY` | API key for activation | (required) |

**PostgreSQL Connection:**

| Variable | Description | Default |
|----------|-------------|---------|
| `PG_CONN_STRING` | Full connection string | (required) |
| `PG_HOST` | PostgreSQL host | `localhost` |
| `PG_PORT` | PostgreSQL port | `5432` |
| `PG_USER` | PostgreSQL username | — |
| `PG_AUTH_METHOD` | Auth method (`cert`, `aws_iam`, `gcp_iam`) | `cert` |
| `PG_TLS_MODE` | TLS mode | `verify-full` |
| `PG_CA_FILE` | CA certificate path | — |
| `PG_CERT_FILE` | Client certificate path | — |
| `PG_KEY_FILE` | Client key path | — |

**Logging and HTTP:**

| Variable | Description | Default |
|----------|-------------|---------|
| `LOG_LEVEL` | Log level (`debug`, `info`, `warn`, `error`) | `info` |
| `LOG_FORMAT` | Log format (`json`, `console`) | `json` |
| `HTTP_ADDRESS` | Health endpoint bind address | `:8080` |

### Usage in Config

```yaml
api_key: "${API_KEY}"

databases:
  - name: Production
    postgres:
      conn_string: "postgres://${PG_USER}@${PG_HOST}:${PG_PORT:-5432}/${PG_DB}?sslmode=verify-full"
```

### Kubernetes Secrets Example

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pg-collector-secrets
type: Opaque
stringData:
  API_KEY: "pgc_pro_abc123..."
  PG_CONN_STRING: "postgres://pgcollector@db:5432/postgres"
---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: pg-collector
          envFrom:
            - secretRef:
                name: pg-collector-secrets
```

### Docker Compose Example

```yaml
services:
  pg-collector:
    image: burnside/pg-collector:latest
    environment:
      - API_KEY=${API_KEY}
      - PG_CONN_STRING=postgres://pgcollector@db:5432/postgres
    env_file:
      - .env
```

### Security Best Practices

- **Never hardcode secrets** in config files — always use `${VAR}` references
- **Use secret managers** in production — AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault, or Kubernetes Secrets
- **Restrict access** to `.env` files — `chmod 600 .env`
- **Validate at startup** — use `pg-collector --check-config` to verify all variables resolve before running

---

## Validation

```bash
pg-collector --check-config --config /etc/pg-collector/config.yaml
```

---

## Demo Mode

For quick evaluation without API key:

```yaml
# Demo mode uses password auth (not for production)
databases:
  - name: local
    postgres:
      conn_string: "postgres://user:pass@localhost:5432/postgres"
      auth_method: password

local:
  enabled: true
  path: ./output
```

> **Note:** Password auth only works in demo builds (`BUILD_MODE=demo`).

---

## Multiple Databases

```yaml
databases:
  - name: Production Primary
    postgres:
      conn_string: "postgres://pgcollector@db1:5432/postgres?sslmode=verify-full"

  - name: Production Replica
    postgres:
      conn_string: "postgres://pgcollector@db2:5432/postgres?sslmode=verify-full"
```

---

## Cloud Examples

### AWS RDS

```yaml
databases:
  - name: RDS Production
    postgres:
      conn_string: "postgres://pgcollector@mydb.xxx.us-east-1.rds.amazonaws.com:5432/postgres"
      auth_method: aws_iam
      aws_iam:
        enabled: true
        region: us-east-1
      tls:
        mode: verify-full
        ca_file: /etc/pg-collector/certs/rds-ca-bundle.pem
```

### GCP Cloud SQL

```yaml
databases:
  - name: Cloud SQL Production
    postgres:
      conn_string: "postgres://pgcollector@/postgres?host=/cloudsql/project:region:instance"
      auth_method: gcp_iam
      gcp_iam:
        enabled: true
```

---

## Related Documentation

- [Quick Start](quick-start.md) - Get started quickly
- [Security Guide](security.md) - TLS and authentication
- [Monitoring](monitoring.md) - Health endpoints
