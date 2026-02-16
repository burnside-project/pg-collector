# Security Guide

PG Collector is designed with security as a core principle. This guide covers authentication setup and security best practices.

## Authentication Methods

| Method | Use Case | Security Level |
|--------|----------|----------------|
| **mTLS (Certificate)** | Self-managed PostgreSQL | Highest |
| **AWS IAM** | Amazon RDS, Aurora | High |
| **GCP IAM** | Google Cloud SQL | High |

**Note:** Password authentication is not supported in production builds. This is intentional - passwords in configuration files are a security risk.

### Demo Mode Exception

For quick evaluation, the **demo build** (`pg-collector-demo`) allows password authentication:

```yaml
# Only in demo builds
postgres:
  conn_string: "postgres://user:password@localhost:5432/postgres"
  auth_method: password
```

Demo builds are for evaluation only. For production, always use mTLS or IAM authentication.

---

## mTLS (Certificate Authentication)

### Overview

mTLS (mutual TLS) provides:
- **Server verification** - Client verifies the database server
- **Client verification** - Server verifies the collector
- **Encryption** - All traffic encrypted in transit
- **No passwords** - Authentication via cryptographic certificates

### Certificate Requirements

| Certificate | Purpose | Location |
|-------------|---------|----------|
| `ca.crt` | Certificate Authority | Collector + PostgreSQL |
| `server.crt` + `server.key` | PostgreSQL server identity | PostgreSQL server |
| `client.crt` + `client.key` | Collector identity | Collector host |

### Step 1: Generate Certificates

For production, use a proper PKI solution:
- **step-ca** (recommended for simplicity)
- HashiCorp Vault PKI
- AWS Private CA
- Your organization's PKI

For testing/development with OpenSSL:

```bash
# Create CA
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.crt -subj "/CN=PG Collector CA"

# Create client certificate (CN must match PostgreSQL username)
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
  -subj "/CN=pgcollector"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt -days 365 -sha256
```

### Step 2: Configure PostgreSQL

**postgresql.conf:**
```ini
ssl = on
ssl_cert_file = '/path/to/server.crt'
ssl_key_file = '/path/to/server.key'
ssl_ca_file = '/path/to/ca.crt'
```

**pg_hba.conf:**
```
# Require certificate authentication for pgcollector
hostssl all pgcollector 0.0.0.0/0 cert clientcert=verify-full
```

Reload PostgreSQL:
```bash
sudo systemctl reload postgresql
```

### Step 3: Configure PG Collector

```yaml
postgres:
  conn_string: "postgres://pgcollector@db.burnsideproject.ai:5432/postgres?sslmode=verify-full"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key
```

### Step 4: Set File Permissions

```bash
sudo mkdir -p /etc/pg-collector/certs
sudo chown -R pg-collector:pg-collector /etc/pg-collector/certs
sudo chmod 700 /etc/pg-collector/certs
sudo chmod 600 /etc/pg-collector/certs/*.key
sudo chmod 644 /etc/pg-collector/certs/*.crt
```

### Step 5: Verify Configuration

```bash
# Validate config syntax
pg-collector --check-config --config /etc/pg-collector/config.yaml

# Test by running (Ctrl+C to stop after verifying connection)
pg-collector --config /etc/pg-collector/config.yaml
```

---

## AWS IAM Authentication

For Amazon RDS and Aurora. See [AWS Setup Guide](aws-setup.md) for complete instructions.

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

---

## GCP IAM Authentication

For Google Cloud SQL. See [GCP Setup Guide](gcp-setup.md) for complete instructions.

```yaml
postgres:
  conn_string: "postgres://pgcollector@/postgres?host=/cloudsql/project:region:instance"
  auth_method: gcp_iam
  gcp_iam:
    enabled: true
```

---

## Security Best Practices

### 1. Minimal Permissions

Only grant necessary permissions:

```sql
CREATE USER pgcollector;
GRANT pg_monitor TO pgcollector;

-- Do NOT grant:
-- - SUPERUSER
-- - CREATE DATABASE
-- - Any write permissions
```

### 2. Network Security

- Run collector on same network as database
- Use private IPs, not public endpoints
- Restrict firewall to necessary IPs only

```bash
# Example: only allow collector IP
sudo ufw allow from 10.0.1.100 to any port 5432
```

### 3. Certificate Rotation

Rotate certificates before expiry:

```bash
# Check certificate expiry
openssl x509 -in /etc/pg-collector/certs/client.crt -noout -dates
```

### 4. Secrets Management

Never store secrets in:
- Configuration files
- Environment variables visible in process lists
- Version control

Use:
- Certificate files with restricted permissions
- IAM roles (AWS/GCP)
- Secrets managers

### 5. Systemd Hardening

```ini
[Service]
User=pg-collector
Group=pg-collector
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/pg-collector
ReadOnlyPaths=/etc/pg-collector
```

---

## Troubleshooting

### Certificate Errors

```bash
# Verify certificate chain
openssl verify -CAfile ca.crt client.crt

# Check certificate details
openssl x509 -in client.crt -text -noout
```

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `certificate verify failed` | CA mismatch | Use correct ca.crt |
| `private key mismatch` | Wrong key file | Regenerate cert/key pair |
| `certificate authentication failed` | CN doesn't match username | CN in cert must equal PostgreSQL username |

---

## Query Masking

PG Collector masks sensitive values in SQL queries before transmission.

### Masking Levels

| Level | Description | Tier |
|-------|-------------|------|
| `none` | No masking | - |
| `basic` | Mask string literals and numbers | Starter |
| `full` | Mask all values including identifiers | Pro |
| `custom` | User-defined patterns | Enterprise |

### Configuration

```yaml
security:
  query_masking_level: basic

  # Custom patterns (Enterprise)
  masking_patterns:
    - "password"
    - "secret"
    - "token"
    - "api_key"
```

### Example

Original query:
```sql
SELECT * FROM users WHERE email = 'john@burnsideproject.ai' AND password = 'secret123'
```

Masked (basic):
```sql
SELECT * FROM users WHERE email = '?' AND password = '?'
```

---

## PII Detection (Enterprise)

Automatically detect and mask personally identifiable information.

```yaml
security:
  pii_detection: true
```

Detected patterns:
- Email addresses
- Phone numbers
- Social Security Numbers
- Credit card numbers

---

## Audit Logging (Enterprise)

Log security-relevant events for compliance.

```yaml
security:
  audit_logging: true
  audit_log_path: /var/log/pg-collector/audit.log
```

Logged events:
- Activation/deactivation
- Configuration changes
- Authentication failures
- Query vault access

---

## IP Allowlist (Enterprise)

Restrict HTTP endpoint access to specific IP addresses or CIDR ranges. This provides network-level access control for the collector's health and metrics endpoints.

### Configuration

```yaml
security:
  ip_allowlist:
    enabled: true
    allowlist:
      - "10.0.0.0/8"           # Private network
      - "192.168.1.100/32"     # Single IP
      - "2001:db8::/32"        # IPv6 CIDR
```

### Features

- **CIDR notation**: Supports both IPv4 and IPv6 ranges
- **Single IPs**: Automatically converts to /32 (IPv4) or /128 (IPv6)
- **Proxy headers**: Reads `X-Forwarded-For` and `X-Real-IP` for client IP
- **Audit logging**: Blocked requests logged to audit log (if enabled)
- **Runtime management**: Add/remove CIDRs without restart (via API)

### Response

When an IP is blocked, the endpoint returns:
```
HTTP/1.1 403 Forbidden
```

---

## Tier Enforcement (Critical)

PG Collector enforces tier limits using **server-provided tier values**. This prevents tier spoofing where a user might try to bypass limits by editing the local configuration.

### How It Works

1. On activation, the Key Service returns the authorized tier for the API key
2. The collector **always uses the server-provided tier**, ignoring any local config overrides
3. If local config tier differs from server tier, a warning is logged

### Security Implications

- **Cannot bypass** tier limits via local configuration
- **Cannot access** Enterprise features with a Starter API key
- **Audit logged** when tier mismatch detected
- **Automatic enforcement** - no manual configuration required

---

## Security Checklist

- [ ] Using certificate or IAM authentication (no passwords)
- [ ] TLS mode set to `verify-full`
- [ ] Certificate files have restricted permissions (600)
- [ ] PostgreSQL user has minimal permissions (pg_monitor only)
- [ ] Network access restricted to necessary IPs
- [ ] IP allowlist configured (Enterprise)
- [ ] Systemd service hardened
- [ ] Certificate rotation scheduled
- [ ] Query masking enabled
- [ ] PII detection enabled (if Enterprise)
