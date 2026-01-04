# GCP Setup Guide

Deploy PG Collector with Google Cloud SQL using IAM authentication.

## Overview

Cloud SQL IAM authentication allows passwordless connections using Google service accounts or user identities.

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

# Get the service account email
SA_EMAIL="pg-collector@PROJECT_ID.iam.gserviceaccount.com"
```

---

## Step 3: Grant Cloud SQL Permissions

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

Connect to your Cloud SQL instance and create the IAM user:

```sql
-- Create IAM user (email without @domain for Cloud SQL)
CREATE USER "pg-collector@PROJECT_ID.iam" WITH LOGIN;

-- Grant monitoring permissions
GRANT pg_monitor TO "pg-collector@PROJECT_ID.iam";
GRANT USAGE ON SCHEMA public TO "pg-collector@PROJECT_ID.iam";
```

**Important:** The PostgreSQL username must match the service account email, but with `.iam` suffix and using the truncated format.

---

## Step 5: Deploy with Service Account

### GCE (Compute Engine)

Attach the service account to your VM:

```bash
gcloud compute instances create pg-collector-vm \
  --service-account=${SA_EMAIL} \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --zone=us-central1-a
```

Or update existing instance:

```bash
gcloud compute instances set-service-account INSTANCE_NAME \
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

### Cloud Run

Deploy with service account:

```bash
gcloud run deploy pg-collector \
  --service-account=${SA_EMAIL} \
  --image=ghcr.io/burnside-project/pg-collector:latest
```

---

## Step 6: Configure PG Collector

### Using Cloud SQL Proxy (Recommended)

```yaml
customer_id: "cust_your_id"
database_id: "db_cloudsql_prod"
tenant_tier: "starter"
output_mode: "s3_only"  # or use GCS

postgres:
  # Connect via Cloud SQL Proxy socket
  conn_string: "postgres://pg-collector@PROJECT_ID.iam@/postgres?host=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME"
  auth_method: gcp_iam
  gcp_iam:
    enabled: true

# For GCS output instead of S3
gcs:
  enabled: true
  bucket: "your-metrics-bucket"
  batch_interval: 5m
  format: "parquet"
```

### Direct Connection (Public IP)

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

If using proxy connection:

```bash
# Download Cloud SQL Proxy
curl -o /usr/local/bin/cloud-sql-proxy \
  https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64

chmod +x /usr/local/bin/cloud-sql-proxy

# Run proxy
cloud-sql-proxy PROJECT_ID:REGION:INSTANCE_NAME &
```

Or as systemd service:

```bash
sudo tee /etc/systemd/system/cloud-sql-proxy.service << 'EOF'
[Unit]
Description=Cloud SQL Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cloud-sql-proxy PROJECT_ID:REGION:INSTANCE_NAME
Restart=always
User=cloudsql

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable cloud-sql-proxy
sudo systemctl start cloud-sql-proxy
```

---

## Step 8: Test Connection

```bash
pg-collector --config /etc/pg-collector/config.yaml --test
```

---

## GCS Output Configuration

For Google Cloud Storage output:

```yaml
gcs:
  enabled: true
  bucket: "your-metrics-bucket"
  key_prefix: "metrics"
  batch_interval: 5m
  format: "parquet"
  compression: "gzip"
```

Grant storage permissions:

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectCreator"
```

---

## Troubleshooting

### "FATAL: password authentication failed"

- IAM auth not enabled on Cloud SQL
- Username format incorrect (must include `.iam` suffix)
- Service account doesn't have `cloudsql.instanceUser` role

### "Permission denied"

- Service account missing `cloudsql.client` role
- Workload Identity not configured correctly (GKE)

### Connection Refused

- Cloud SQL Proxy not running
- Private IP connectivity issue
- Firewall rules blocking connection

### Token Errors

- Application Default Credentials not set
- Service account key expired (if using key file)

---

## Security Best Practices

1. **Use Cloud SQL Proxy** instead of public IP
2. **Enable private IP** for Cloud SQL
3. **Use Workload Identity** on GKE
4. **Enable Cloud Audit Logs** for database access
5. **Restrict service account permissions** to minimum required
6. **Use VPC Service Controls** for additional security
