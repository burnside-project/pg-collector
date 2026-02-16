# Device Activation

PG Collector uses an IoT-style device activation model. Each collector instance is a "device" that activates once and maintains persistent identity.

---

## Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Config    │ ──▶ │ Key Service │ ──▶ │  Activated  │
│  (api_key)  │     │  (validate) │     │  (running)  │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Key concepts:**

- **Single command activation** — just run `pg-collector --config config.yaml`
- **API key exchanged for JWT tokens** — key is sent once, then tokens handle auth
- **Tier derived from subscription** — your plan determines features and limits
- **Persistent device identity** — survives restarts via local state database
- **Grace period** — continues collecting if the platform is temporarily unreachable

---

## Getting an API Key

1. Log in to the [Burnside Dashboard](https://dashboard.burnsideproject.ai)
2. Navigate to **Collector API Keys**
3. Click **Create Key**
4. Copy the generated key

**Key format:**

```
pgc_{tier}_{32_char_random}
```

| Prefix | Plan |
|--------|------|
| `pgc_demo_` | Demo (no subscription required) |
| `pgc_starter_` | Starter |
| `pgc_pro_` | Pro |
| `pgc_business_` | Business |
| `pgc_enterprise_` | Enterprise |

!!! tip

    You can use the same API key across multiple collector instances. Each collector automatically registers with a unique identity.

---

## Minimal Configuration

Only the API key and a database connection are required. Everything else is derived from the platform:

```yaml
# /etc/pg-collector/config.yaml
api_key: "${PG_COLLECTOR_API_KEY}"

databases:
  - name: "Production Primary"
    postgres:
      conn_string: "postgres://pgcollector@host:5432/db?sslmode=verify-full"
      auth_method: cert
      tls:
        mode: verify-full
        ca_file: /etc/pg-collector/certs/ca.crt
        cert_file: /etc/pg-collector/certs/client.crt
        key_file: /etc/pg-collector/certs/client.key
```

**Derived automatically from the platform after activation:**

- Device identity — generated on first activation
- Tier and features — from your subscription
- Output destination and limits — from tier configuration

See [Configuration Guide](configuration.md) for the full reference.

---

## First Run

Activation happens automatically on the first run:

```bash
export PG_COLLECTOR_API_KEY="pgc_pro_abc123..."
pg-collector --config /etc/pg-collector/config.yaml
```

**What happens:**

1. Generates a unique device identity
2. Sends the API key to the Burnside platform for validation
3. Receives JWT tokens and tier information
4. Stores device state locally (survives restarts)
5. Begins collecting metrics

**On subsequent runs:**

- Loads state from local storage
- Uses cached tokens (auto-refreshes before expiry)
- Never sends the API key again — only JWT tokens are used after activation

---

## Device Lifecycle

```
                    ┌──────────────────┐
                    │  UNPROVISIONED   │
                    │  (first run)     │
                    └────────┬─────────┘
                             │ activate with API key
                             ▼
                    ┌──────────────────┐
        ┌──────────│     ACTIVE       │◀─────────┐
        │          │  (online, synced) │          │
        │          └────────┬─────────┘          │
        │                   │                     │
        │ subscription      │ platform            │ reconnect +
        │ cancelled         │ unreachable         │ sync success
        │                   ▼                     │
        │          ┌──────────────────┐          │
        │          │      GRACE       │──────────┘
        │          │ (offline, cached) │
        │          └────────┬─────────┘
        │                   │ grace period expires
        │                   ▼
        │          ┌──────────────────┐
        └─────────▶│     STOPPED      │
                   │ (no collection)  │
                   └──────────────────┘
```

| State | Description | Collecting? |
|-------|-------------|:-----------:|
| **UNPROVISIONED** | First run, no activation yet | No |
| **ACTIVE** | Online, tokens valid, syncing with platform | Yes |
| **GRACE** | Platform unreachable, using cached configuration | Yes |
| **STOPPED** | Grace period expired or subscription cancelled | No |

---

## Grace Period

When the Burnside platform is temporarily unreachable, the collector enters **grace mode**:

1. Continues collecting metrics using cached configuration
2. Buffers data locally (memory + disk)
3. Retries the platform connection periodically
4. If reconnected within the grace period — resumes normal operation and flushes buffered data
5. If the grace period expires — stops collecting until connectivity is restored

Grace period duration depends on your subscription plan. See [Subscription Plans](plans.md) for details.

---

## Multi-Collector Fleet

### Same API Key, Unique Collectors

All collectors in a fleet can use the same API key. Each collector automatically registers with a unique identity:

```yaml
# Same config deployed to all collectors
api_key: "${PG_COLLECTOR_API_KEY}"  # Same key for all

# Each collector monitors its local database
databases:
  - name: "${HOSTNAME}-db"          # Unique per host
    postgres:
      conn_string: "postgres://pgcollector@localhost:5432/db"
```

### Dashboard View

Manage all collectors from the Burnside Dashboard:

```
Customer Account (Pro plan)
└── API Key: pgc_pro_xxx
    ├── collector-1 (prod-db-1) — 2 DBs — Last sync: 5m ago
    ├── collector-2 (prod-db-2) — 3 DBs — Last sync: 2m ago
    └── collector-3 (staging)   — 1 DB  — Last sync: 1m ago
```

- **Revoke individual collectors** without affecting others
- **Track usage per collector** for monitoring and billing
- **Send commands to specific collectors** (config updates, restart)

---

## CLI Commands

| Command | Purpose |
|---------|---------|
| `pg-collector --config config.yaml` | Start collector (activates on first run) |
| `pg-collector --status` | Check running status, tier, and last sync time |
| `pg-collector --deactivate` | Remove local activation state (re-activates on next run) |
| `pg-collector --check-config --config config.yaml` | Validate configuration without starting |

See [CLI Reference](cli-reference.md) for the full command reference.

---

## Troubleshooting

### "No activation found"

```
activation failed: no state.db found
```

**Solution:** Ensure your API key is set in the config file or environment variable, then start the collector.

### "API key mismatch"

```
activation failed: API key hash mismatch
```

**Solution:** The API key in your config differs from the one used to activate. Run `pg-collector --deactivate` to reset, then restart with the correct key.

### "Grace period expired"

```
device stopped: grace period expired
```

**Solution:**

1. Check network connectivity to the Burnside platform
2. Run `pg-collector --deactivate`
3. Restart the collector to re-activate

### "Key revoked"

```
device stopped: key revoked
```

**Solution:** Generate a new API key in the Dashboard, update your config, run `pg-collector --deactivate`, and restart.

---

## Security

- **API key** is only sent once during activation, over HTTPS
- **API key hash** is stored locally as SHA-256 — the plaintext key is not retained
- **JWT tokens** are short-lived (1 hour) and auto-rotated before expiry
- **Local state** is protected by file permissions (mode 600)
- **No secrets in logs** — tokens and keys are redacted from all log output

---

## Related Documentation

- [Subscription Plans](plans.md) — Compare plans and grace periods
- [Architecture Overview](architecture.md) — How PG Collector works
- [Configuration Guide](configuration.md) — Full configuration reference
- [Security Guide](security.md) — Authentication methods and TLS setup
