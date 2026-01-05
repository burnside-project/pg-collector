# Configuration Guide

Complete reference for PG Collector configuration.

## Configuration File

Default location: `/etc/pg-collector/config.yaml`

Override with: `pg-collector --config /path/to/config.yaml`

---

## Full Configuration Reference

```yaml
# =============================================================================
# IDENTITY
# =============================================================================

# Customer identifier (provided during onboarding)
customer_id: "your_customer_id"

# Unique identifier for this database
database_id: "db_prod_01"

# Human-readable name (optional)
database_name: "Production Database"

# =============================================================================
# POSTGRESQL CONNECTION
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
# OUTPUT CONFIGURATION
# =============================================================================

output:
  # Output type: s3, gcs
  type: s3

  # AWS S3 settings
  region: "us-east-1"
  bucket: "your-metrics-bucket"

  # Batching
  batch_interval: 5m
  batch_max_size: 50MB

  # Format: json, parquet
  format: "parquet"

  # Compression: gzip, zstd, none
  compression: "gzip"

# =============================================================================
# SAMPLING INTERVALS
# =============================================================================

sampling:
  # Activity metrics
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
# RESOURCE LIMITS
# =============================================================================

limits:
  # Maximum memory for buffering
  memory_buffer_size: 50MB

  # Maximum disk buffer size
  disk_buffer_size: 500MB

  # Disk buffer location
  disk_buffer_path: /var/lib/pg-collector/buffer.db

# =============================================================================
# HEALTH ENDPOINTS
# =============================================================================

health:
  enabled: true
  address: "0.0.0.0:8080"

# =============================================================================
# LOGGING
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

output:
  type: s3
  region: "us-east-1"
  bucket: "metrics-bucket"
```

---

## Cloud-Specific Examples

### AWS RDS

```yaml
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
postgres:
  conn_string: "postgres://pgcollector@/postgres?host=/cloudsql/project:region:instance"
  auth_method: gcp_iam
  gcp_iam:
    enabled: true
```

---

## Tuning Guide

### High-Frequency Monitoring

```yaml
sampling:
  activity: 500ms
  replication: 500ms
```

### Low-Resource Environment

```yaml
limits:
  memory_buffer_size: 25MB
  disk_buffer_size: 100MB

sampling:
  activity: 5s
  database: 30s
  statements: 60s
```

---

## Related Documentation

- [Security Guide](security.md) - TLS and authentication
- [AWS Setup](aws-setup.md) - RDS configuration
- [GCP Setup](gcp-setup.md) - Cloud SQL configuration
