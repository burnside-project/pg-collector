# AWS Setup Guide

Deploy PG Collector with Amazon RDS and Aurora using IAM authentication.

## Overview

AWS IAM database authentication allows you to connect to RDS/Aurora without passwords. The collector uses temporary tokens generated from IAM credentials.

**Benefits:**
- No password management
- Automatic credential rotation
- Fine-grained IAM policies
- CloudTrail audit logging

---

## Prerequisites

- Amazon RDS or Aurora PostgreSQL instance
- IAM permissions to create roles and policies
- PG Collector installed on EC2, ECS, or Lambda

---

## Step 1: Enable IAM Authentication on RDS

### Console

1. Go to RDS Console → Select your instance
2. Click **Modify**
3. Under **Database authentication**, select **Password and IAM database authentication**
4. Click **Continue** → **Apply immediately**

### CLI

```bash
aws rds modify-db-instance \
  --db-instance-identifier mydb \
  --enable-iam-database-authentication \
  --apply-immediately
```

---

## Step 2: Create Database User

Connect to your database:

```sql
-- Create user with rds_iam role
CREATE USER pgcollector WITH LOGIN;
GRANT rds_iam TO pgcollector;

-- Grant monitoring permissions
GRANT pg_monitor TO pgcollector;
```

---

## Step 3: Create IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "rds-db:connect",
      "Resource": "arn:aws:rds-db:REGION:ACCOUNT_ID:dbuser:DBI_RESOURCE_ID/pgcollector"
    }
  ]
}
```

Replace:
- `REGION` with your region (e.g., `us-east-1`)
- `ACCOUNT_ID` with your AWS account ID
- `DBI_RESOURCE_ID` with your database resource ID (found in RDS Console → Configuration)

---

## Step 4: Create IAM Role

### For EC2

```bash
# Create role
aws iam create-role \
  --role-name pg-collector-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policy
aws iam attach-role-policy \
  --role-name pg-collector-role \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/pg-collector-rds-connect

# Create instance profile and attach to EC2
aws iam create-instance-profile --instance-profile-name pg-collector-profile
aws iam add-role-to-instance-profile \
  --instance-profile-name pg-collector-profile \
  --role-name pg-collector-role
```

### For ECS

Add the policy to your ECS task role.

---

## Step 5: Download RDS CA Certificate

```bash
curl -o /etc/pg-collector/certs/rds-ca-bundle.pem \
  https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

sudo chmod 644 /etc/pg-collector/certs/rds-ca-bundle.pem
```

---

## Step 6: Configure PG Collector

```yaml
customer_id: "your_customer_id"
database_id: "db_rds_prod"

postgres:
  conn_string: "postgres://pgcollector@mydb.xxxxx.us-east-1.rds.amazonaws.com:5432/postgres?sslmode=verify-full"
  auth_method: aws_iam
  aws_iam:
    enabled: true
    region: "us-east-1"
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/rds-ca-bundle.pem

output:
  type: s3
  region: "us-east-1"
  bucket: "your-metrics-bucket"
```

---

## Step 7: Test Connection

```bash
pg-collector --config /etc/pg-collector/config.yaml --test
```

---

## Aurora Notes

### Use Reader Endpoint

Use the reader endpoint for monitoring to avoid impacting writes:

```yaml
postgres:
  conn_string: "postgres://pgcollector@mydb.cluster-ro-xxxxx.us-east-1.rds.amazonaws.com:5432/postgres?sslmode=verify-full"
```

---

## S3 Output Permissions

Add S3 permissions to the same IAM role:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:GetObject"
  ],
  "Resource": "arn:aws:s3:::your-metrics-bucket/*"
}
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| PAM authentication failed | IAM auth not enabled | Enable on RDS instance |
| Access denied | Policy resource ARN wrong | Verify region, account ID, DBI resource ID |
| Connection timeout | Security group | Allow inbound port 5432 |

---

## Security Best Practices

1. **Use VPC endpoints** for S3
2. **Restrict IAM policy** to specific database
3. **Enable CloudTrail** for audit logging
4. **Use reader endpoint** for Aurora clusters
