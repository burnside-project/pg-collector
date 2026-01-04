# Security Guide

PG Collector is designed with security as a core principle. This guide covers authentication setup and security best practices.

## Authentication Methods

| Method | Use Case | Security Level |
|--------|----------|----------------|
| **mTLS (Certificate)** | Self-managed PostgreSQL | Highest |
| **AWS IAM** | Amazon RDS, Aurora | High |
| **GCP IAM** | Google Cloud SQL | High |

**Note:** Password authentication is not supported. This is intentional - passwords in configuration files are a security risk.

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
| `client.crt` + `client.key` | Collector identity | Collector |

### Step 1: Generate Certificates

Using OpenSSL (for testing/development):

```bash
# Create CA
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.crt -subj "/CN=PG Collector CA"

# Create server certificate
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
  -subj "/CN=your-db-hostname"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -days 365 -sha256

# Create client certificate (CN must match PostgreSQL username)
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
  -subj "/CN=pgcollector"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt -days 365 -sha256
```

For production, use a proper PKI solution like:
- **step-ca** (recommended)
- HashiCorp Vault PKI
- AWS Private CA
- Your organization's PKI

### Step 2: Configure PostgreSQL

**postgresql.conf:**
```ini
# Enable SSL
ssl = on
ssl_cert_file = '/var/lib/postgresql/certs/server.crt'
ssl_key_file = '/var/lib/postgresql/certs/server.key'
ssl_ca_file = '/var/lib/postgresql/certs/ca.crt'
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
  conn_string: "postgres://pgcollector@db.example.com:5432/postgres?sslmode=verify-full"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key
```

### Step 4: Set File Permissions

```bash
# Collector certificate directory
sudo mkdir -p /etc/pg-collector/certs
sudo chown -R pg-collector:pg-collector /etc/pg-collector/certs
sudo chmod 700 /etc/pg-collector/certs
sudo chmod 600 /etc/pg-collector/certs/*.key
sudo chmod 644 /etc/pg-collector/certs/*.crt
```

### Step 5: Test Connection

```bash
# Test with psql first
psql "host=db.example.com port=5432 dbname=postgres user=pgcollector \
  sslmode=verify-full sslcert=/etc/pg-collector/certs/client.crt \
  sslkey=/etc/pg-collector/certs/client.key \
  sslrootcert=/etc/pg-collector/certs/ca.crt"

# Then test with pg-collector
pg-collector --config /etc/pg-collector/config.yaml --test
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
-- Minimal permissions for monitoring
CREATE USER pgcollector;
GRANT pg_monitor TO pgcollector;
GRANT USAGE ON SCHEMA public TO pgcollector;

-- Do NOT grant:
-- - SUPERUSER
-- - CREATE DATABASE
-- - CREATE ROLE
-- - Any write permissions
```

### 2. Network Security

```bash
# Run collector on same network as database
# Use private IPs, not public

# Firewall: only allow collector IP to PostgreSQL port
sudo ufw allow from 10.0.1.100 to any port 5432
```

### 3. Certificate Rotation

Rotate certificates before expiry:

```bash
# Check certificate expiry
openssl x509 -in /etc/pg-collector/certs/client.crt -noout -dates

# Set up cron for rotation
0 0 1 * * /usr/local/bin/rotate-certs.sh
```

### 4. Secrets Management

Never store secrets in:
- Configuration files (use cert auth instead)
- Environment variables (visible in process list)
- Version control

Use:
- Certificate files with restricted permissions
- AWS Secrets Manager / IAM roles
- HashiCorp Vault

### 5. Audit Logging

Enable PostgreSQL audit logging:

```ini
# postgresql.conf
log_connections = on
log_disconnections = on
log_statement = 'ddl'
```

### 6. Systemd Hardening

```ini
[Service]
# Drop privileges
User=pg-collector
Group=pg-collector

# Filesystem restrictions
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/pg-collector
ReadOnlyPaths=/etc/pg-collector

# Network restrictions (if not needed)
# PrivateNetwork=yes

# Capability restrictions
CapabilityBoundingSet=
AmbientCapabilities=
```

---

## Troubleshooting

### Certificate Errors

```bash
# Verify certificate chain
openssl verify -CAfile ca.crt client.crt

# Check certificate details
openssl x509 -in client.crt -text -noout

# Test SSL connection
openssl s_client -connect db.example.com:5432 -starttls postgres
```

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `certificate verify failed` | CA mismatch | Use correct ca.crt |
| `private key mismatch` | Wrong key file | Regenerate cert/key pair |
| `FATAL: certificate authentication failed` | CN doesn't match username | CN in cert must equal PostgreSQL username |
| `SSL SYSCALL error` | Network/firewall issue | Check connectivity |

---

## Security Checklist

- [ ] Using certificate or IAM authentication (no passwords)
- [ ] TLS mode set to `verify-full`
- [ ] Certificate files have restricted permissions (600)
- [ ] PostgreSQL user has minimal permissions (pg_monitor only)
- [ ] Network access restricted to necessary IPs
- [ ] Systemd service hardened
- [ ] Certificate rotation scheduled
- [ ] Audit logging enabled
