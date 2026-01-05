# Monitoring Guide

Monitor PG Collector health and performance.

## Health Endpoints

PG Collector exposes HTTP endpoints for monitoring:

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Basic health check (for load balancers) |
| `GET /status` | Detailed status information |
| `GET /metrics` | Prometheus metrics |

---

## Health Check

### Basic Health

```bash
curl http://localhost:8080/health
```

Response:
```json
{
  "status": "healthy",
  "postgres": "connected",
  "output": "ok"
}
```

### Detailed Status

```bash
curl http://localhost:8080/status
```

Response:
```json
{
  "status": "healthy",
  "uptime": "2h15m30s",
  "version": "0.1.0",
  "postgres": {
    "status": "connected",
    "host": "db.example.com:5432",
    "latency_ms": 2
  },
  "output": {
    "type": "s3",
    "status": "ok",
    "last_upload": "2025-01-04T12:00:00Z"
  },
  "buffer": {
    "memory_used": 1024,
    "memory_max": 52428800,
    "disk_used": 0,
    "disk_max": 524288000
  },
  "sampling": {
    "last_sample": "2025-01-04T12:00:01Z",
    "samples_collected": 12500
  }
}
```

---

## Prometheus Metrics

### Endpoint

```bash
curl http://localhost:8080/metrics
```

### Key Metrics

#### Connection Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `pg_collector_postgres_connected` | Gauge | 1 if connected, 0 otherwise |
| `pg_collector_postgres_latency_seconds` | Histogram | Query latency |
| `pg_collector_postgres_errors_total` | Counter | Connection/query errors |

#### Buffer Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `pg_collector_buffer_memory_bytes` | Gauge | Memory buffer usage |
| `pg_collector_buffer_disk_bytes` | Gauge | Disk buffer usage |
| `pg_collector_buffer_overflow_total` | Counter | Memory to disk overflows |

#### Output Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `pg_collector_output_success_total` | Counter | Successful uploads |
| `pg_collector_output_errors_total` | Counter | Failed uploads |
| `pg_collector_output_bytes_total` | Counter | Bytes uploaded |
| `pg_collector_output_latency_seconds` | Histogram | Upload latency |

#### Sampling Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `pg_collector_samples_total` | Counter | Total samples collected |
| `pg_collector_sample_errors_total` | Counter | Sample collection errors |

---

## Health Check Integration

### Kubernetes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

### AWS ALB/NLB

Target group health check:
- **Path:** `/health`
- **Port:** `8080`
- **Healthy threshold:** 2
- **Unhealthy threshold:** 3
- **Interval:** 30 seconds

### Docker Compose

```yaml
services:
  pg-collector:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

## Prometheus Configuration

### Scrape Config

```yaml
scrape_configs:
  - job_name: 'pg-collector'
    static_configs:
      - targets: ['pg-collector:8080']
    scrape_interval: 30s
    metrics_path: /metrics
```

### Kubernetes ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: pg-collector
spec:
  selector:
    matchLabels:
      app: pg-collector
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

---

## Alerting Rules

### Prometheus Alerts

```yaml
groups:
  - name: pg-collector
    rules:
      - alert: PGCollectorDown
        expr: up{job="pg-collector"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "PG Collector is down"

      - alert: PGCollectorPostgresDisconnected
        expr: pg_collector_postgres_connected == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "PG Collector lost database connection"

      - alert: PGCollectorBufferHigh
        expr: pg_collector_buffer_disk_bytes > 100000000
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "PG Collector disk buffer > 100MB"

      - alert: PGCollectorOutputErrors
        expr: rate(pg_collector_output_errors_total[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "PG Collector output errors detected"
```

---

## Logging

### Log Levels

| Level | Description |
|-------|-------------|
| `debug` | Verbose debugging information |
| `info` | Normal operational messages |
| `warn` | Warning conditions |
| `error` | Error conditions |

### Configuration

```yaml
logging:
  level: info
  format: json
  output: stdout
```

### Log Format (JSON)

```json
{
  "time": "2025-01-04T12:00:00Z",
  "level": "info",
  "msg": "Sample collected",
  "sampler": "activity",
  "duration_ms": 15
}
```

### View Logs

```bash
# Systemd
sudo journalctl -u pg-collector -f

# Docker
docker logs -f pg-collector

# Kubernetes
kubectl logs -f deployment/pg-collector
```

---

## Troubleshooting

### Collector Not Healthy

1. Check logs for errors:
   ```bash
   sudo journalctl -u pg-collector -n 100
   ```

2. Test database connection:
   ```bash
   pg-collector --config /etc/pg-collector/config.yaml --test
   ```

3. Check output destination accessibility

### High Buffer Usage

Buffer filling up indicates output issues:

1. Check output status in `/status`
2. Verify network connectivity to S3/Kafka
3. Check IAM permissions
4. Review output error logs

### Missing Metrics

If Prometheus isn't scraping:

1. Verify endpoint is accessible:
   ```bash
   curl http://localhost:8080/metrics
   ```

2. Check firewall allows port 8080

3. Verify Prometheus scrape config

---

## Related Documentation

- [Troubleshooting](troubleshooting.md)
- [Configuration](configuration.md)
- [CLI Reference](cli-reference.md)
