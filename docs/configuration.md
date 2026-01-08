# Configuration Guide

Complete reference for PG Collector configuration.

## Configuration File

Default location: `/etc/pg-collector/config.yaml`

Override with: `pg-collector --config /path/to/config.yaml`

---

## Full Configuration Reference

```yaml
# =============================================================================
# IDENTITY (Required)
# =============================================================================

# Customer identifier (provided during onboarding)
customer_id: "your_customer_id"

# Unique identifier for this database
database_id: "db_prod_01"

# Human-readable name (optional)
database_name: "Production Database"

# =============================================================================
# POSTGRESQL CONNECTION (Required)
# =============================================================================

postgres:
  # Connection string
  conn_string: "postgres://pgcollector@db.example.com:5432/postgres?sslmode=verify-full"

  # Authentication method: cert, aws_iam, gcp_iam
  auth_method: cert

  # Query timeout (protects against blocking)
  query_timeout: 5s

  # TLS configuration
  tls:
    # Mode: disable, require, verify-ca, verify-full
    mode: verify-full

    # CA certificate for server verification
    ca_file: /etc/pg-collector/certs/ca.crt

    # Client certificate (for mTLS)
    cert_file: /etc/pg-collector/certs/client.crt

    # Client private key (for mTLS)
    key_file: /etc/pg-collector/certs/client.key

  # AWS IAM authentication (for RDS/Aurora)
  aws_iam:
    enabled: false
    region: "us-east-1"

  # GCP IAM authentication (for Cloud SQL)
  gcp_iam:
    enabled: false

# =============================================================================
# SAMPLING INTERVALS (Optional)
# =============================================================================

# Adjust based on your subscription tier and monitoring needs
sampling:
  # Activity metrics (sessions, wait events)
  activity: 1s

  # Database-level stats
  database: 10s

  # Statement statistics
  statements: 30s

  # Background writer stats
  bgwriter: 10s

  # Replication metrics
  replication: 1s

  # Vacuum progress
  vacuum: 30s

  # Table/index statistics
  tables: 60s

# =============================================================================
# RESOURCE LIMITS (Optional)
# =============================================================================

limits:
  # Maximum memory for buffering (default: 50MB)
  memory_buffer_size: 50MB

  # Maximum disk buffer size (default: 500MB)
  disk_buffer_size: 500MB

  # Disk buffer location
  disk_buffer_path: /var/lib/pg-collector/buffer.db

# =============================================================================
# HEALTH ENDPOINTS (Optional)
# =============================================================================

health:
  enabled: true
  address: "0.0.0.0:8080"

# =============================================================================
# LOGGING (Optional)
# =============================================================================

logging:
  # Level: debug, info, warn, error
  level: info

  # Format: json, text
  format: json

  # Output: stdout, file
  output: stdout
```

---

## Environment Variables

All configuration options can be set via environment variables:

```bash
export PG_COLLECTOR_CUSTOMER_ID="cust_123"
export PG_COLLECTOR_DATABASE_ID="db_prod"
export PG_COLLECTOR_POSTGRES_CONN_STRING="postgres://..."
```

Pattern: `PG_COLLECTOR_<SECTION>_<KEY>` (uppercase, underscores)

---

## Configuration Precedence

1. Command-line flags (highest)
2. Environment variables
3. Configuration file
4. Default values (lowest)

---

## Validation

Validate configuration before starting:

```bash
pg-collector --config /etc/pg-collector/config.yaml --validate
```

---

## Minimal Configuration

Smallest working configuration:

```yaml
customer_id: "cust_123"
database_id: "db_01"

postgres:
  conn_string: "postgres://pgcollector@localhost:5432/postgres"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key
```

---

## Cloud-Specific Examples

### AWS RDS

```yaml
customer_id: "cust_123"
database_id: "db_rds_prod"

postgres:
  conn_string: "postgres://pgcollector@mydb.xxx.us-east-1.rds.amazonaws.com:5432/postgres?sslmode=verify-full"
  auth_method: aws_iam
  aws_iam:
    enabled: true
    region: "us-east-1"
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/rds-ca-bundle.pem
```

### GCP Cloud SQL

```yaml
customer_id: "cust_123"
database_id: "db_cloudsql_prod"

postgres:
  conn_string: "postgres://pgcollector@/postgres?host=/cloudsql/project:region:instance"
  auth_method: gcp_iam
  gcp_iam:
    enabled: true
```

### Self-Managed PostgreSQL

```yaml
customer_id: "cust_123"
database_id: "db_onprem_prod"

postgres:
  conn_string: "postgres://pgcollector@db.internal:5432/postgres?sslmode=verify-full"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key
```

---

## Sampling Interval Guidelines

Intervals vary by subscription tier:

| Sampler | Starter | Pro | Enterprise |
|---------|---------|-----|------------|
| Activity | 30s | 10s | 1s |
| Database | 30s | 10s | 10s |
| Statements | 60s | 30s | 30s |
| Replication | 30s | 5s | 1s |

Higher-frequency sampling provides more granular insights but generates more data.

---

## Multiple Databases

To monitor multiple databases, run one PG Collector instance per database. Each instance needs:
- Unique `database_id`
- Its own configuration file
- Separate health endpoint port (if on same host)

Example for multiple instances on the same host:

**Instance 1:** `/etc/pg-collector/db1.yaml`
```yaml
customer_id: "cust_123"
database_id: "db_prod_01"
health:
  address: "0.0.0.0:8080"
postgres:
  conn_string: "postgres://pgcollector@db1.internal:5432/postgres"
  # ...
```

**Instance 2:** `/etc/pg-collector/db2.yaml`
```yaml
customer_id: "cust_123"
database_id: "db_prod_02"
health:
  address: "0.0.0.0:8081"
postgres:
  conn_string: "postgres://pgcollector@db2.internal:5432/postgres"
  # ...
```

---

## Demo Mode Configuration

For quick evaluation without certificate setup, use the demo build.

### Demo Configuration Example

```yaml
customer_id: "demo"
database_id: "my_db"
output_mode: local_only

postgres:
  conn_string: "postgres://user:password@localhost:5432/postgres"
  auth_method: password  # Only in demo builds

local:
  enabled: true
  path: ./output
  format: jsonl
  split_by_metric_type: true
```

### Demo Output Options

| Output Mode | Description |
|-------------|-------------|
| `local_only` | Write metrics to local filesystem |
| `s3_only` | Write metrics to S3-compatible storage |

### Local Output Configuration

```yaml
local:
  enabled: true
  path: ./output              # Output directory
  format: jsonl               # jsonl or parquet
  rotate_interval: 1h         # File rotation interval
  max_file_size: 100MB        # Max file size before rotation
  flush_interval: 10s         # Buffer flush interval
  split_by_metric_type: true  # Separate files per metric type
```

### S3 Output Configuration (Demo)

```yaml
output_mode: s3_only

s3:
  enabled: true
  region: "us-east-1"
  bucket: "your-bucket-name"
  key_prefix: "pg-collector"
  format: parquet            # parquet or json
  batch_interval: 5m
  batch_max_size: 50MB
```

### Demo Limitations

| Feature | Demo | Production |
|---------|------|------------|
| Password auth | Allowed | Not supported |
| mTLS/IAM auth | Supported | Required |
| Local output | Yes | Yes |
| S3 output | Yes | Yes |
| Platform output | No | Yes |

For production deployments, use the standard build with mTLS or IAM authentication.

---

## Related Documentation

- [Security Guide](security.md) - TLS and authentication
- [AWS Setup](aws-setup.md) - RDS configuration
- [GCP Setup](gcp-setup.md) - Cloud SQL configuration
- [Troubleshooting](troubleshooting.md) - Common issues
