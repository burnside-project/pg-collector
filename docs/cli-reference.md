# CLI Reference

Command-line options for PG Collector.

## Usage

```bash
pg-collector --config /etc/pg-collector/config.yaml
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--config` | Path to configuration file | `/etc/pg-collector/config.yaml` |
| `--check-config` | Validate configuration and exit | - |
| `--status` | Check if collector is running | - |
| `--deactivate` | Remove activation and exit | - |
| `--state-db` | Path to device state database | `/var/lib/pg-collector/state.db` |
| `--pid-file` | Path to PID file | `/var/run/pg-collector.pid` |
| `--version` | Print version and exit | - |
| `--version-json` | Print version as JSON | - |

## Examples

### Start Collector

```bash
pg-collector --config /etc/pg-collector/config.yaml
```

On first run, automatically activates using `api_key` from config file.

### Validate Configuration

```bash
pg-collector --check-config --config /etc/pg-collector/config.yaml
```

Output:
```
Configuration file /etc/pg-collector/config.yaml is valid
  Plan:       pro
  Databases:  1
```

### Check Status

```bash
pg-collector --status
```

Output:
```
pg-collector is running (PID 12345)
  Version: 1.0.0
  Commit:  abc1234
```

### Print Version

```bash
pg-collector --version
```

Output:
```
pg-collector 1.0.0 (abc1234)
```

### Deactivate

```bash
pg-collector --deactivate
```

Removes stored state. Next run will re-activate using `api_key` from config.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |

## Environment Variables

Override configuration via environment:

| Variable | Description |
|----------|-------------|
| `PG_COLLECTOR_LOG_LEVEL` | Log level: debug, info, warn, error |
| `PG_COLLECTOR_LOG_FORMAT` | Log format: json, console |

### Environment Variable Expansion in Config

Use `${VAR}` syntax in configuration files:

```yaml
api_key: "${PG_COLLECTOR_API_KEY}"
# Plan is derived automatically from activation
```

Supported syntax:
- `${VAR}` - Required variable (fails if not set)
- `${VAR:-default}` - Use default if not set

## Signals

| Signal | Action |
|--------|--------|
| `SIGTERM` | Graceful shutdown |
| `SIGINT` | Graceful shutdown |

### Graceful Shutdown

On shutdown signal:
1. Stop schedulers (no new samples)
2. Flush buffers
3. Close database connections
4. Exit
