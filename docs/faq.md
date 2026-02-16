# Frequently Asked Questions

Quick answers to common questions.

---

## General

### What PostgreSQL versions are supported?

PostgreSQL 12 and later. Some features (like certain pg_stat views) require newer versions.

### Does PG Collector impact database performance?

**No.** PG Collector is designed from the ground up for zero database impact:
- Read-only queries with timeout protection
- Maximum 2 database connections
- Automatic backoff when your database is busy
- No locks, no writes, no schema changes

### What platforms are supported?

- **Linux:** x86_64 (amd64), ARM64
- **macOS:** Intel, Apple Silicon
- **Windows:** x86_64

### Can I monitor multiple databases?

Run one PG Collector instance per database. Each instance connects to a single PostgreSQL database.

---

## Installation

### Where is the binary installed?

Default location: `/usr/local/bin/pg-collector`

### Where are configuration files?

Default location: `/etc/pg-collector/config.yaml`

### Where are certificates stored?

Recommended location: `/etc/pg-collector/certs/`

### Where is the buffer stored?

Default location: `/var/lib/pg-collector/buffer.db`

---

## Authentication

### Why isn't password authentication supported in production?

**Security first.** Storing passwords in configuration files creates unnecessary risk. Certificate and IAM authentication eliminate password management entirely—no rotation, no exposure in logs, no secrets to protect.

*Note: Password auth is available in [demo builds](quick-start.md#demo-mode-quick-evaluation) for evaluation purposes.*

### Can I use AWS IAM with self-managed PostgreSQL?

No, AWS IAM authentication only works with Amazon RDS and Aurora.

### My certificates expired. What do I do?

1. Generate new certificates
2. Update PostgreSQL server if CA changed
3. Update collector with new certificates
4. Restart the collector

---

## Connectivity

### What ports does PG Collector use?

- **Outbound:** PostgreSQL port (usually 5432)
- **Outbound:** Burnside cloud (HTTPS 443)
- **Inbound:** Health endpoint (default 8080)

### Can I run behind a proxy?

Yes, set standard proxy environment variables:
```bash
export HTTPS_PROXY=http://proxy:8080
```

### What happens during network outages?

Metrics are buffered locally (memory, then disk) and sent when connectivity is restored. No data is lost during temporary outages.

---

## Operations

### How do I check if it's working?

```bash
# Check health
curl http://localhost:8080/health

# Check status
curl http://localhost:8080/status

# Check logs
sudo journalctl -u pg-collector -f
```

### How do I upgrade?

1. Download new version
2. Stop service: `sudo systemctl stop pg-collector`
3. Replace binary: `sudo mv pg-collector /usr/local/bin/`
4. Start service: `sudo systemctl start pg-collector`

### How do I change configuration?

1. Edit `/etc/pg-collector/config.yaml`
2. Validate: `pg-collector --check-config --config /etc/pg-collector/config.yaml`
3. Restart: `sudo systemctl restart pg-collector`

---

## Troubleshooting

### The service keeps restarting

Check logs for the cause:
```bash
sudo journalctl -u pg-collector -n 100
```

Common causes:
- Invalid configuration
- Cannot connect to PostgreSQL
- Certificate issues

### High memory usage

Check your buffer configuration:
```yaml
buffers:
  memory_capacity: 1000  # Number of samples to buffer
```

Reduce if needed, or check for output issues causing backpressure.

### Connection refused errors

1. Check PostgreSQL is running
2. Check firewall allows connection
3. Check pg_hba.conf permits the connection
4. Test with psql directly

---

## Security

### Is data encrypted in transit?

Yes, when using `sslmode=verify-full` (recommended), all connections are TLS encrypted.

### Is data encrypted at rest?

The local buffer is not encrypted. The Burnside cloud encrypts all data at rest.

### What permissions does the PostgreSQL user need?

```sql
GRANT pg_monitor TO pgcollector;
```

This provides read-only access to monitoring views.

---

## Support

### Where do I report bugs?

[GitHub Issues](https://github.com/burnside-project/pg-collector/issues) — We actively monitor and respond.

### How do I get commercial support?

Email [support@burnsideproject.ai](mailto:support@burnsideproject.ai) — Pro and Enterprise customers get priority response.

### I have a feature request

We'd love to hear it! Open a [GitHub Issue](https://github.com/burnside-project/pg-collector/issues) with the "enhancement" label, or email us directly.

### Where is the full documentation?

You're reading it! Also available at [github.com/burnside-project/pg-collector/docs](https://github.com/burnside-project/pg-collector/docs/)
