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

Connect to your database and create the monitoring user:

```sql
-- Create user with rds_iam role (enables IAM auth)
CREATE USER pgcollector WITH LOGIN;
GRANT rds_iam TO pgcollector;

-- Grant monitoring permissions
GRANT pg_monitor TO pgcollector;
GRANT USAGE ON SCHEMA public TO pgcollector;
```

---

## Step 3: Create IAM Policy

Create an IAM policy for database access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "rds-db:connect",
      "Resource": "arn:aws:rds-db:us-east-1:123456789012:dbuser:db-XXXXX/pgcollector"
    }
  ]
}
```

Replace:
- `us-east-1` with your region
- `123456789012` with your AWS account ID
- `db-XXXXX` with your DBI resource ID (found in RDS console → Configuration)
- `pgcollector` with your database username

---

## Step 4: Create IAM Role

### For EC2

Create a role with the policy and attach to your EC2 instance:

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
  --policy-arn arn:aws:iam::123456789012:policy/pg-collector-rds-connect

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name pg-collector-profile

aws iam add-role-to-instance-profile \
  --instance-profile-name pg-collector-profile \
  --role-name pg-collector-role

# Attach to EC2 instance
aws ec2 associate-iam-instance-profile \
  --instance-id i-1234567890abcdef0 \
  --iam-instance-profile Name=pg-collector-profile
```

### For ECS

Add the policy to your ECS task role.

### For Lambda

Add the policy to your Lambda execution role.

---

## Step 5: Download RDS CA Certificate

```bash
# Download RDS CA bundle
curl -o /etc/pg-collector/certs/rds-ca-bundle.pem \
  https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

# Set permissions
sudo chmod 644 /etc/pg-collector/certs/rds-ca-bundle.pem
```

---

## Step 6: Configure PG Collector

```yaml
customer_id: "cust_your_id"
database_id: "db_rds_prod"
tenant_tier: "starter"
output_mode: "s3_only"

postgres:
  conn_string: "postgres://pgcollector@mydb.xxxxx.us-east-1.rds.amazonaws.com:5432/postgres?sslmode=verify-full"
  auth_method: aws_iam
  aws_iam:
    enabled: true
    region: "us-east-1"
    # Optional: specify role ARN if not using instance profile
    # role_arn: "arn:aws:iam::123456789012:role/pg-collector-role"
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/rds-ca-bundle.pem

s3:
  enabled: true
  region: "us-east-1"
  bucket: "your-metrics-bucket"
  batch_interval: 5m
  format: "parquet"
```

---

## Step 7: Test Connection

```bash
pg-collector --config /etc/pg-collector/config.yaml --test
```

---

## Aurora-Specific Notes

### Aurora Cluster Endpoint

Use the **reader endpoint** for monitoring to avoid impacting writes:

```yaml
postgres:
  conn_string: "postgres://pgcollector@mydb.cluster-ro-xxxxx.us-east-1.rds.amazonaws.com:5432/postgres?sslmode=verify-full"
```

### Aurora Serverless v2

IAM authentication works the same way. Ensure your ACU (Aurora Capacity Units) settings allow for the additional connection.

---

## S3 Output Configuration

For S3 output, the EC2 instance/ECS task also needs S3 permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-metrics-bucket",
        "arn:aws:s3:::your-metrics-bucket/*"
      ]
    }
  ]
}
```

---

## Troubleshooting

### "PAM authentication failed"

IAM auth not enabled on RDS instance, or user doesn't have `rds_iam` role.

### "Token expired"

IAM tokens are valid for 15 minutes. The collector automatically refreshes them.

### "Access denied"

Check IAM policy resource ARN matches exactly:
- Correct region
- Correct account ID
- Correct DBI resource ID
- Correct username

### Connection Timeout

- Check security group allows inbound on port 5432
- Check VPC routing if collector is in different VPC
- Check RDS is publicly accessible (if connecting from outside VPC)

---

## Security Best Practices

1. **Use VPC endpoints** for S3 to keep traffic private
2. **Restrict IAM policy** to specific database resource
3. **Enable CloudTrail** for audit logging
4. **Use reader endpoint** for Aurora clusters
5. **Set up alarms** for failed authentication attempts
