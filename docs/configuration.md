# Configuration Guide

Complete reference for all PG Collector configuration options.

## Configuration File

Default location: `/etc/pg-collector/config.yaml`

Override with: `pg-collector --config /path/to/config.yaml`

## Full Configuration Reference

```yaml
# =============================================================================
# IDENTITY
# =============================================================================

# Customer identifier (provided by Burnside Project)
customer_id: "cust_your_id"

# Unique identifier for this database
database_id: "db_prod_01"

# Human-readable name
database_name: "Production Database"

# Subscription tier: starter, pro, enterprise
tenant_tier: "starter"

# =============================================================================
# OUTPUT MODE
# =============================================================================

# Output destination:
#   s3_only              - Send metrics to S3 (Starter/Pro)
#   kafka_only           - Send metrics to Kafka (Enterprise)
#   kafka_with_s3_fallback - Kafka primary, S3 fallback (Enterprise)
output_mode: "s3_only"

# =============================================================================
# POSTGRESQL CONNECTION
# =============================================================================

postgres:
  # Connection string (without password for cert auth)
  conn_string: "postgres://pgcollector@db.example.com:5432/postgres?sslmode=verify-full"

  # Authentication method: cert, aws_iam, gcp_iam
  auth_method: cert

  # Connection pool size (max 2 recommended)
  pool_size: 2

  # Query timeout
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
    # Uses instance profile by default, or specify:
    # role_arn: "arn:aws:iam::123456789:role/rds-connect"

  # GCP IAM authentication (for Cloud SQL)
  gcp_iam:
    enabled: false
    # Uses default credentials or specify service account

# =============================================================================
# S3 OUTPUT
# =============================================================================

s3:
  enabled: true

  # AWS region
  region: "us-east-1"

  # Bucket name
  bucket: "your-metrics-bucket"

  # Key prefix for all objects
  key_prefix: "metrics"

  # Batch settings
  batch_interval: 5m      # Flush interval
  batch_max_size: 50MB    # Max batch size before flush
  batch_max_records: 10000 # Max records before flush

  # Output format: json, parquet
  format: "parquet"

  # Compression: gzip, zstd, none
  compression: "gzip"

  # Dead letter queue for failed uploads
  dlq:
    enabled: true
    prefix: "_dlq"

# =============================================================================
# KAFKA OUTPUT (Enterprise only)
# =============================================================================

kafka:
  enabled: false
  brokers:
    - "kafka-1.example.com:9092"
    - "kafka-2.example.com:9092"

  topic_prefix: "pg-metrics"

  # Producer settings
  batch_size: 100
  batch_timeout: 1s
  compression: "lz4"
  acks: 1  # 0=none, 1=leader, -1=all

  # TLS
  tls:
    enabled: true
    ca_file: /etc/pg-collector/certs/kafka-ca.crt
    cert_file: /etc/pg-collector/certs/kafka-client.crt
    key_file: /etc/pg-collector/certs/kafka-client.key

  # SASL authentication
  sasl:
    enabled: false
    mechanism: "SCRAM-SHA-256"
    username: ""
    password: ""

# =============================================================================
# SAMPLING INTERVALS
# =============================================================================

sampling:
  # Activity metrics (pg_stat_activity)
  activity: 1s

  # Database-level stats
  database: 10s

  # Statement statistics (pg_stat_statements)
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
  # Maximum memory for buffering (bytes)
  memory_buffer_size: 52428800  # 50MB

  # Maximum disk buffer size (bytes)
  disk_buffer_size: 524288000   # 500MB

  # Disk buffer location
  disk_buffer_path: /var/lib/pg-collector/buffer.db

# =============================================================================
# HEALTH & METRICS
# =============================================================================

health:
  # HTTP server for health endpoints
  enabled: true
  address: "0.0.0.0:8080"

  # Endpoints:
  #   /health  - Basic health check
  #   /status  - Detailed status
  #   /metrics - Prometheus metrics

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

  # File output settings
  file:
    path: /var/log/pg-collector/collector.log
    max_size: 100MB
    max_backups: 3
    max_age: 7  # days

# =============================================================================
# CIRCUIT BREAKER
# =============================================================================

circuit_breaker:
  # PostgreSQL circuit breaker
  postgres:
    threshold: 5        # Failures before opening
    timeout: 30s        # Time before half-open
    half_open_max: 2    # Requests in half-open state

  # Output circuit breaker (S3/Kafka)
  output:
    threshold: 3
    timeout: 60s
    half_open_max: 1
```

## Environment Variables

All configuration options can be set via environment variables:

```bash
export PG_COLLECTOR_CUSTOMER_ID="cust_123"
export PG_COLLECTOR_DATABASE_ID="db_prod"
export PG_COLLECTOR_POSTGRES_CONN_STRING="postgres://..."
export PG_COLLECTOR_S3_BUCKET="my-bucket"
```

Pattern: `PG_COLLECTOR_<SECTION>_<KEY>` (uppercase, underscores)

## Configuration Precedence

1. Command-line flags (highest)
2. Environment variables
3. Configuration file
4. Default values (lowest)

## Validation

Validate your configuration:

```bash
pg-collector --config /etc/pg-collector/config.yaml --validate
```

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

s3:
  enabled: true
  region: "us-east-1"
  bucket: "metrics-bucket"
```
