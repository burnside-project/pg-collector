# Monitoring Guide

Monitor PG Collector health and performance with built-in endpoints and Prometheus integration.

## Health Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Component health check |
| `GET /status` | Detailed status and buffer info |
| `GET /livez` | Kubernetes liveness probe |
| `GET /readyz` | Kubernetes readiness probe |
| `GET /metrics` | Prometheus metrics |
| `GET /version` | Build version information |
| `GET /watchdog` | Watchdog health status |

---

## Health Check

```bash
curl http://localhost:8080/health
```

Response:
```json
{
  "status": "ok",
  "components": {
    "postgres": {
      "status": "ok"
    },
    "output": {
      "status": "ok"
    }
  },
  "timestamp": "2026-01-31T12:00:00Z"
}
```

**Status values:**
- `ok` - All components healthy
- `degraded` - One or more components unhealthy

**Component status values:**
- `ok` - Connected and working
- `down` - Connection failed
- `degraded` - Circuit breaker open
- `unknown` - Not configured

---

## Status Endpoint

```bash
curl http://localhost:8080/status
```

Response:
```json
{
  "buffer_depth": 150,
  "last_push_time": "2026-01-31T12:00:00Z",
  "postgres_connections": 2,
  "is_draining": false
}
```

The status endpoint returns current buffer depth, last successful output time, active PostgreSQL connections, and whether the disk buffer is currently draining.

---

## Kubernetes Probes

### Liveness Probe

```bash
curl http://localhost:8080/livez
```

Returns `200 OK` if alive, `503` if dead components detected.

### Readiness Probe

```bash
curl http://localhost:8080/readyz
```

Returns `200 OK` if ready, `503` if required components are not connected.

### Pod Configuration

```yaml
livenessProbe:
  httpGet:
    path: /livez
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /readyz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

---

## Prometheus Metrics

```bash
curl http://localhost:8080/metrics
```

### Key Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `pg_collector_up` | Gauge | Whether the collector is running (1 = up, 0 = down) |
| `pg_collector_uptime_seconds` | Gauge | Time since collector started |
| `pg_collector_samples_total` | Counter | Total samples collected |
| `pg_collector_sample_errors_total` | Counter | Sample collection errors |
| `pg_collector_buffer_memory_bytes` | Gauge | Memory buffer usage |
| `pg_collector_buffer_disk_bytes` | Gauge | Disk buffer usage |
| `pg_collector_output_success_total` | Counter | Successful outputs |
| `pg_collector_output_errors_total` | Counter | Failed outputs |
| `pg_collector_circuit_breaker_state` | Gauge | Circuit breaker state (0 = closed, 1 = half-open, 2 = open) |
| `pg_collector_pg_query_duration_seconds` | Histogram | PostgreSQL query execution time |
| `pg_collector_panics_recovered_total` | Counter | Total recovered panics |

### Scrape Config

```yaml
scrape_configs:
  - job_name: 'pg-collector'
    static_configs:
      - targets: ['pg-collector:8080']
    scrape_interval: 30s
    metrics_path: /metrics
```

---

## Alerting Rules

### Recommended Alerts

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
          description: "PG Collector has been unreachable for 5 minutes."

      - alert: PGCollectorPostgresDown
        expr: pg_collector_circuit_breaker_state{component="postgres"} == 2
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL connection circuit breaker is open"
          description: "PG Collector cannot reach PostgreSQL. Circuit breaker is open."

      - alert: PGCollectorDiskBufferActive
        expr: pg_collector_buffer_disk_bytes > 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Disk buffer is active"
          description: "Samples are spilling to disk buffer, indicating output delivery issues."

      - alert: PGCollectorNoSamples
        expr: rate(pg_collector_samples_total[5m]) == 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "No samples collected"
          description: "PG Collector has not collected any samples in the last 10 minutes."

      - alert: PGCollectorDegraded
        expr: pg_collector_health_status != 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "PG Collector is degraded"
          description: "One or more components are unhealthy."

      - alert: PGCollectorBufferHigh
        expr: pg_collector_buffer_disk_bytes > 100000000
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Disk buffer exceeds 100 MB"
          description: "Disk buffer is growing, indicating persistent output delivery failure."
```

### Prometheus Operator ServiceMonitor

If you use the Prometheus Operator, create a `ServiceMonitor` to auto-discover PG Collector:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: pg-collector
  labels:
    release: prometheus
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

## Logging

### Configuration

```yaml
log:
  level: info    # debug, info, warn, error
  format: json   # json, console
```

### View Logs

```bash
# Systemd
journalctl -u pg-collector -f

# Docker
docker logs -f pg-collector

# Kubernetes
kubectl logs -f deployment/pg-collector
```

### Structured Log Format

When `format: json` is set (the default), PG Collector outputs structured JSON logs:

```json
{"level":"info","ts":"2026-01-15T10:30:00Z","msg":"sample collected","sampler":"activity","database":"prod-db-1","duration_ms":12}
{"level":"info","ts":"2026-01-15T10:30:05Z","msg":"sync complete","samples":847,"latency_ms":120}
{"level":"warn","ts":"2026-01-15T10:31:00Z","msg":"entering grace mode","reason":"key service unreachable"}
```

### Log Levels

| Level | Use |
|-------|-----|
| `debug` | Detailed diagnostic information (verbose, use for troubleshooting) |
| `info` | Normal operational events |
| `warn` | Recoverable issues that may need attention |
| `error` | Failures that prevent normal operation |

### Important Log Patterns

Watch for these log messages to understand collector behavior:

| Pattern | Level | Meaning |
|---------|-------|---------|
| `circuit breaker opened` | WARN | Too many failures to a component; retries paused |
| `circuit breaker closed` | INFO | Component recovered; normal operation resumed |
| `disk buffer activated` | WARN | Memory buffer full, samples writing to disk |
| `disk buffer drained` | INFO | Disk buffer emptied, back to memory-only |
| `device activated` | INFO | Activation successful, collecting started |
| `entering grace mode` | WARN | Platform unreachable, using cached configuration |
| `grace period expired` | ERROR | Collection stopped; needs reconnection |
| `sync complete` | INFO | Successful data delivery to platform |

---

## Watchdog

The watchdog monitors collector health and detects stuck components.

```bash
curl http://localhost:8080/watchdog
```

Response:

```json
{
  "status": "ok",
  "components": {
    "scheduler": { "status": "ok", "last_tick": "2026-01-15T10:30:00Z" },
    "buffer": { "status": "ok", "depth": 150 },
    "output": { "status": "ok", "last_success": "2026-01-15T10:29:55Z" },
    "postgres": { "status": "ok", "connections": 2 }
  },
  "uptime_seconds": 86400
}
```

**Component states:**

| State | Description |
|-------|-------------|
| `ok` | Component is healthy and operating normally |
| `degraded` | Component is operational but experiencing issues (e.g., circuit breaker half-open) |
| `down` | Component has failed (e.g., PostgreSQL unreachable) |
| `unknown` | Component is not configured or has not reported status |

---

## Docker Health Check

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

## AWS ALB/NLB

Target group health check:
- **Path:** `/health`
- **Port:** `8080`
- **Healthy threshold:** 2
- **Unhealthy threshold:** 3
- **Interval:** 30 seconds
