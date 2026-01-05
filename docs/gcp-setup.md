# GCP Setup Guide

Deploy PG Collector with Google Cloud SQL using IAM authentication.

## Overview

Cloud SQL IAM authentication allows passwordless connections using Google service accounts.

**Benefits:**
- No password management
- Automatic credential rotation
- IAM-based access control
- Cloud Audit Logs integration

---

## Prerequisites

- Google Cloud SQL PostgreSQL instance
- IAM permissions to manage service accounts
- PG Collector installed on GCE, GKE, or Cloud Run

---

## Step 1: Enable IAM Authentication

### Console

1. Go to Cloud SQL Console → Select your instance
2. Click **Edit**
3. Under **Connections**, enable **Cloud SQL IAM authentication**
4. Click **Save**

### gcloud CLI

```bash
gcloud sql instances patch INSTANCE_NAME \
  --database-flags cloudsql.iam_authentication=on
```

---

## Step 2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create pg-collector \
  --display-name="PG Collector Service Account"

# Note the email
SA_EMAIL="pg-collector@PROJECT_ID.iam.gserviceaccount.com"
```

---

## Step 3: Grant Permissions

```bash
# Grant Cloud SQL Client role
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudsql.client"

# Grant Cloud SQL Instance User role
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudsql.instanceUser"
```

---

## Step 4: Create Database User

Connect to your Cloud SQL instance:

```sql
-- Create IAM user
CREATE USER "pg-collector@PROJECT_ID.iam" WITH LOGIN;

-- Grant monitoring permissions
GRANT pg_monitor TO "pg-collector@PROJECT_ID.iam";
```

**Note:** Username format must include `.iam` suffix.

---

## Step 5: Deploy with Service Account

### GCE (Compute Engine)

```bash
gcloud compute instances create pg-collector-vm \
  --service-account=${SA_EMAIL} \
  --scopes=https://www.googleapis.com/auth/cloud-platform
```

### GKE (Kubernetes)

Use Workload Identity:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pg-collector
  annotations:
    iam.gke.io/gcp-service-account: pg-collector@PROJECT_ID.iam.gserviceaccount.com
```

---

## Step 6: Configure PG Collector

### With Cloud SQL Proxy (Recommended)

```yaml
customer_id: "your_customer_id"
database_id: "db_cloudsql_prod"

postgres:
  conn_string: "postgres://pg-collector@PROJECT_ID.iam@/postgres?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME"
  auth_method: gcp_iam
  gcp_iam:
    enabled: true

output:
  type: gcs
  bucket: "your-metrics-bucket"
```

### Direct Connection

```yaml
postgres:
  conn_string: "postgres://pg-collector@PROJECT_ID.iam@INSTANCE_IP:5432/postgres?sslmode=verify-full"
  auth_method: gcp_iam
  gcp_iam:
    enabled: true
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/server-ca.pem
```

---

## Step 7: Install Cloud SQL Proxy

```bash
# Download
curl -o /usr/local/bin/cloud-sql-proxy \
  https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64

chmod +x /usr/local/bin/cloud-sql-proxy

# Run
cloud-sql-proxy PROJECT_ID:REGION:INSTANCE_NAME &
```

---

## Step 8: Test Connection

```bash
pg-collector --config /etc/pg-collector/config.yaml --test
```

---

## GCS Output Permissions

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectCreator"
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Password authentication failed | IAM auth not enabled | Enable on Cloud SQL |
| Permission denied | Missing IAM role | Add `cloudsql.instanceUser` role |
| Connection refused | Proxy not running | Start Cloud SQL Proxy |

---

## Security Best Practices

1. **Use Cloud SQL Proxy** instead of public IP
2. **Enable private IP** for Cloud SQL
3. **Use Workload Identity** on GKE
4. **Enable Cloud Audit Logs**
