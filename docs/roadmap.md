# Roadmap

> **Last updated:** January 2025

This roadmap outlines our planned development for PG Collector and the Burnside observability platform. Priorities may shift based on customer feedback and market demands.

---

## Legend

| Status | Meaning |
|--------|---------|
| ✅ | Shipped |
| 🚧 | In progress |
| 📋 | Planned |
| 🔬 | Research/Exploration |

---

## Q1 2025 — Foundation

### PG Collector Agent
| Feature | Status | Notes |
|---------|--------|-------|
| PostgreSQL 14-17 support | ✅ | Full compatibility |
| mTLS authentication | ✅ | Production-ready |
| AWS IAM (RDS/Aurora) | ✅ | Passwordless auth |
| GCP IAM (Cloud SQL) | ✅ | Passwordless auth |
| Local-only demo mode | ✅ | For evaluation |
| Multi-platform binaries | ✅ | Linux, macOS, Windows |
| Systemd & Docker deployment | ✅ | Production-ready |

### Cloud Platform
| Feature | Status | Notes |
|---------|--------|-------|
| Claude 3.5 Haiku integration | ✅ | AI-powered predictions |
| Slack alerting | ✅ | Real-time notifications |
| PagerDuty integration | ✅ | Incident escalation |
| Tiered pricing (Starter/Pro/Enterprise) | ✅ | Live |

---

## Q2 2025 — Enterprise & Scale

### Multi-Database Support
| Feature | Status | Target |
|---------|--------|--------|
| **MySQL/MariaDB collector** | 🚧 | Q2 2025 |
| AWS Aurora MySQL | 📋 | Q2 2025 |
| Azure Database for MySQL | 📋 | Q2 2025 |

### Cloud Provider Integrations
| Feature | Status | Target |
|---------|--------|--------|
| **AWS CloudWatch metrics ingestion** | 🚧 | Q2 2025 |
| AWS RDS Performance Insights correlation | 📋 | Q2 2025 |
| Azure Monitor integration | 📋 | Q3 2025 |

### Enterprise Features
| Feature | Status | Target |
|---------|--------|--------|
| SSO/SAML authentication | 📋 | Q2 2025 |
| Custom alert routing rules | 📋 | Q2 2025 |
| Audit logging | 📋 | Q2 2025 |
| Multi-tenant organization support | 📋 | Q2 2025 |

---

## Q3 2025 — Intelligence & Automation

### Advanced AI Capabilities
| Feature | Status | Target |
|---------|--------|--------|
| Automated root cause analysis | 📋 | Q3 2025 |
| Query optimization recommendations | 📋 | Q3 2025 |
| Capacity planning forecasts | 📋 | Q3 2025 |
| Natural language query interface | 🔬 | Q3-Q4 2025 |

### Automation & Remediation
| Feature | Status | Target |
|---------|--------|--------|
| Runbook automation triggers | 📋 | Q3 2025 |
| Terraform/Pulumi integration | 📋 | Q3 2025 |
| Auto-scaling recommendations | 🔬 | Q4 2025 |

---

## Q4 2025 — Platform Expansion

### Additional Database Engines
| Feature | Status | Target |
|---------|--------|--------|
| **MongoDB collector** | 🔬 | Q4 2025 |
| **Redis collector** | 🔬 | Q4 2025 |
| Amazon DocumentDB | 🔬 | Q4 2025 |
| CockroachDB | 🔬 | TBD |

### Platform Capabilities
| Feature | Status | Target |
|---------|--------|--------|
| Custom dashboards | 📋 | Q4 2025 |
| API access (Pro/Enterprise) | 📋 | Q4 2025 |
| Webhook integrations | 📋 | Q4 2025 |
| Data export (S3, BigQuery) | 📋 | Q4 2025 |

---

## Future Exploration

These items are on our radar but not yet committed to specific timelines:

- **Edge ML inference** — Run lightweight prediction models directly in the collector
- **eBPF-based collection** — Kernel-level observability without database queries
- **Distributed tracing correlation** — Connect database insights with APM tools
- **Cost optimization insights** — Cloud spend analysis tied to database patterns
- **Compliance reporting** — SOC 2, HIPAA, PCI-DSS report generation

---

## Request a Feature

Have a feature request or want to influence our roadmap?

- **GitHub Issues:** [Open a feature request](https://github.com/burnside-project/pg-collector/issues/new?labels=enhancement)
- **Email:** [product@burnsideproject.ai](mailto:product@burnsideproject.ai)
- **Customer portal:** Enterprise customers can submit requests via the dashboard

---

## Release Cadence

- **Patch releases (x.x.X):** As needed for bug fixes and security updates
- **Minor releases (x.X.0):** Monthly, with new features and improvements
- **Major releases (X.0.0):** Quarterly, may include breaking changes

Subscribe to release notifications by watching this repository or emailing [updates@burnsideproject.ai](mailto:updates@burnsideproject.ai).

---

*This roadmap is provided for informational purposes and does not constitute a commitment. Features and timelines are subject to change.*
