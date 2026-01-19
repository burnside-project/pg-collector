# Security Policy

## Supported Versions

We actively support security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | ✅ Active support  |
| 0.2.x   | ⚠️ Critical fixes only |
| < 0.2   | ❌ No longer supported |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in PG Collector, please report it responsibly.

### How to Report

**Email:** (mailto:security@burnsideproject.ai)

**Please include:**
- Description of the vulnerability
- Steps to reproduce
- Affected versions
- Potential impact assessment
- Any suggested remediation (optional)

### What to Expect

| Timeframe | Action |
|-----------|--------|
| **24 hours** | Acknowledgment of your report |
| **72 hours** | Initial assessment and severity classification |
| **7 days** | Detailed response with remediation plan |
| **30 days** | Target resolution for critical/high severity issues |

### Severity Classification

We use CVSS 3.1 to classify vulnerabilities:

- **Critical (9.0-10.0):** Immediate action, patch within 7 days
- **High (7.0-8.9):** Priority fix, patch within 14 days
- **Medium (4.0-6.9):** Scheduled fix, patch within 30 days
- **Low (0.1-3.9):** Addressed in next regular release

### Safe Harbor

We consider security research conducted in good faith to be authorized. We will not pursue legal action against researchers who:

- Make a good faith effort to avoid privacy violations and data destruction
- Only interact with accounts you own or with explicit permission
- Do not exploit vulnerabilities beyond what is necessary to demonstrate the issue
- Report vulnerabilities promptly and do not disclose publicly until we've had reasonable time to address them

### Recognition

We maintain a security acknowledgments page for researchers who report valid vulnerabilities. Let us know if you'd like to be credited.

---

## Security Architecture

### Authentication

PG Collector supports secure authentication methods designed for production environments:

| Method | Use Case | Security Level |
|--------|----------|----------------|
| **mTLS Certificates** | Self-managed PostgreSQL | Highest |
| **AWS IAM** | RDS, Aurora | High (passwordless) |
| **GCP IAM** | Cloud SQL | High (passwordless) |

**Production binaries do not support password authentication.** Demo binaries support password auth for evaluation purposes only.

### Data in Transit

- All communication with Burnside cloud infrastructure uses TLS 1.3
- PostgreSQL connections require `sslmode=verify-full` in production
- Certificate verification is mandatory; self-signed certificates are not supported in production mode

### Data at Rest

- Telemetry data is encrypted at rest in our cloud infrastructure (AES-256)
- Local buffering (during network outages) uses encrypted storage
- No credentials are stored in configuration files when using IAM authentication

### Minimal Privilege

PG Collector requires minimal PostgreSQL permissions:

```sql
-- Recommended role setup
CREATE ROLE pgcollector WITH LOGIN;
GRANT pg_monitor TO pgcollector;
GRANT CONNECT ON DATABASE postgres TO pgcollector;
```

The collector:
- Uses a maximum of 2 concurrent connections
- Executes read-only queries with statement timeouts
- Never modifies database state or schema

### Network Security

- Outbound connections only (no inbound ports required)
- Configurable egress endpoints for air-gapped environments
- Proxy support for environments with restricted internet access

---

## Compliance

PG Collector is designed with compliance requirements in mind:

- **SOC 2 Type II:** Burnside cloud infrastructure (in progress)
- **GDPR:** Query masking prevents PII capture in statement analytics
- **HIPAA:** Available under BAA for healthcare customers (Enterprise tier)

---

## Security Updates

Security advisories are published via:

1. [GitHub Security Advisories](https://github.com/burnside-project/pg-collector/security/advisories)
2. Email notifications to registered customers
3. Release notes for patched versions

To receive security notifications, email [security@burnsideproject.ai](mailto:security@burnsideproject.ai) with subject "Subscribe to security updates".

---

## Contact

- **Security issues:** [security@burnsideproject.ai](mailto:security@burnsideproject.ai)
- **General support:** [support@burnsideproject.ai](mailto:support@burnsideproject.ai)
- **PGP Key:** Available upon request for encrypted communications
