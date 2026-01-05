# CLI Reference

Command-line options and usage for PG Collector.

## Basic Usage

```bash
pg-collector [OPTIONS]
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--config FILE` | Path to configuration file | `/etc/pg-collector/config.yaml` |
| `--validate` | Validate configuration and exit | - |
| `--test` | Test connections and exit | - |
| `--diagnostics` | Print diagnostic information | - |
| `--version` | Print version and exit | - |
| `--help` | Show help message | - |

## Examples

### Start with Configuration

```bash
pg-collector --config /etc/pg-collector/config.yaml
```

### Validate Configuration

```bash
pg-collector --config /etc/pg-collector/config.yaml --validate
```

Output:
```
Configuration valid
```

### Test Connections

```bash
pg-collector --config /etc/pg-collector/config.yaml --test
```

Output:
```
Testing PostgreSQL connection... OK
  Host: db.example.com:5432
  Version: PostgreSQL 15.2
  User: pgcollector

Testing output destination... OK
  Type: s3
  Bucket: metrics-bucket

All tests passed
```

### Print Version

```bash
pg-collector --version
```

Output:
```
pg-collector version 1.0.0 (commit: abc1234, built: 2025-01-01T00:00:00Z)
```

### Print Diagnostics

```bash
pg-collector --config /etc/pg-collector/config.yaml --diagnostics
```

Output:
```
PG Collector Diagnostics
========================
Version: 1.0.0
OS: linux/amd64
Go: 1.22.0

Configuration:
  File: /etc/pg-collector/config.yaml
  Valid: true

PostgreSQL:
  Host: db.example.com:5432
  Status: connected
  Version: 15.2

Output:
  Type: s3
  Status: ok

Resources:
  Memory: 45MB / 50MB
  Disk buffer: 0MB / 500MB
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Connection error |

## Environment Variables

Configuration can also be set via environment variables:

```bash
export PG_COLLECTOR_CUSTOMER_ID="cust_123"
export PG_COLLECTOR_DATABASE_ID="db_prod"
export PG_COLLECTOR_POSTGRES_CONN_STRING="postgres://..."
```

Pattern: `PG_COLLECTOR_<SECTION>_<KEY>` (uppercase, underscores)

## Signals

| Signal | Action |
|--------|--------|
| `SIGTERM` | Graceful shutdown |
| `SIGINT` | Graceful shutdown |
| `SIGHUP` | Reload configuration |

## Logging

Control log output:

```yaml
logging:
  level: info    # debug, info, warn, error
  format: json   # json, text
  output: stdout # stdout, file
```

Or via environment:

```bash
export PG_COLLECTOR_LOGGING_LEVEL=debug
```
