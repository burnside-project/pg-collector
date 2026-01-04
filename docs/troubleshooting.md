# Troubleshooting Guide

Common issues and solutions for PG Collector.

## Quick Diagnostics

```bash
# Check service status
sudo systemctl status pg-collector

# View recent logs
sudo journalctl -u pg-collector -n 50

# Test configuration
pg-collector --config /etc/pg-collector/config.yaml --validate

# Test connection
pg-collector --config /etc/pg-collector/config.yaml --test

# Check health endpoint
curl http://localhost:8080/health
```

---

## Connection Issues

### Cannot connect to PostgreSQL

**Symptoms:**
```
ERROR: connection refused
ERROR: connection timed out
```

**Solutions:**

1. **Check network connectivity:**
   ```bash
   nc -zv db.example.com 5432
   telnet db.example.com 5432
   ```

2. **Check PostgreSQL is listening:**
   ```bash
   # On the database server
   sudo ss -tlnp | grep 5432
   ```

3. **Check pg_hba.conf allows connection:**
   ```bash
   # Ensure your IP is allowed
   hostssl all pgcollector YOUR_IP/32 cert
   ```

4. **Check firewall:**
   ```bash
   # AWS Security Group - ensure inbound 5432 is allowed
   # GCP Firewall - ensure ingress rule exists
   sudo ufw status  # Linux
   ```

### Certificate authentication failed

**Symptoms:**
```
FATAL: certificate authentication failed for user "pgcollector"
SSL error: certificate verify failed
```

**Solutions:**

1. **Verify certificate CN matches username:**
   ```bash
   openssl x509 -in /etc/pg-collector/certs/client.crt -noout -subject
   # Should show: subject= /CN=pgcollector
   ```

2. **Verify certificate chain:**
   ```bash
   openssl verify -CAfile /etc/pg-collector/certs/ca.crt \
     /etc/pg-collector/certs/client.crt
   ```

3. **Check certificate expiry:**
   ```bash
   openssl x509 -in /etc/pg-collector/certs/client.crt -noout -dates
   ```

4. **Check file permissions:**
   ```bash
   ls -la /etc/pg-collector/certs/
   # .key files should be 600
   # .crt files should be 644
   ```

5. **Test with psql first:**
   ```bash
   psql "host=db.example.com port=5432 dbname=postgres user=pgcollector \
     sslmode=verify-full \
     sslcert=/etc/pg-collector/certs/client.crt \
     sslkey=/etc/pg-collector/certs/client.key \
     sslrootcert=/etc/pg-collector/certs/ca.crt"
   ```

### AWS IAM authentication failed

**Symptoms:**
```
FATAL: PAM authentication failed
ERROR: could not get IAM auth token
```

**Solutions:**

1. **Check IAM authentication is enabled on RDS:**
   ```bash
   aws rds describe-db-instances --db-instance-identifier mydb \
     --query 'DBInstances[0].IAMDatabaseAuthenticationEnabled'
   ```

2. **Verify user has rds_iam role:**
   ```sql
   SELECT rolname, rolcanlogin FROM pg_roles WHERE rolname = 'pgcollector';
   \du pgcollector
   -- Should show rds_iam in member of
   ```

3. **Check IAM policy resource ARN:**
   - Region correct?
   - Account ID correct?
   - DBI resource ID correct? (not instance name)
   - Username correct?

4. **Test token generation:**
   ```bash
   aws rds generate-db-auth-token \
     --hostname mydb.xxx.us-east-1.rds.amazonaws.com \
     --port 5432 \
     --username pgcollector
   ```

---

## Output Issues

### S3 upload failed

**Symptoms:**
```
ERROR: failed to upload to S3
ERROR: Access Denied
```

**Solutions:**

1. **Check IAM permissions:**
   ```json
   {
     "Effect": "Allow",
     "Action": ["s3:PutObject", "s3:GetObject"],
     "Resource": "arn:aws:s3:::bucket-name/*"
   }
   ```

2. **Check bucket exists and region is correct:**
   ```bash
   aws s3 ls s3://your-bucket/
   ```

3. **Check bucket policy allows writes:**
   ```bash
   aws s3api get-bucket-policy --bucket your-bucket
   ```

4. **Test S3 access:**
   ```bash
   echo "test" | aws s3 cp - s3://your-bucket/test.txt
   ```

### Kafka connection failed

**Symptoms:**
```
ERROR: kafka: client has run out of available brokers
ERROR: kafka: failed to produce message
```

**Solutions:**

1. **Check broker connectivity:**
   ```bash
   nc -zv kafka-broker:9092
   ```

2. **Check TLS configuration if enabled**

3. **Verify topic exists:**
   ```bash
   kafka-topics.sh --list --bootstrap-server kafka:9092
   ```

---

## Performance Issues

### High memory usage

**Symptoms:**
- Memory usage exceeds configured limit
- OOM kills

**Solutions:**

1. **Check buffer configuration:**
   ```yaml
   limits:
     memory_buffer_size: 52428800  # 50MB default
   ```

2. **Check for output backpressure:**
   ```bash
   curl http://localhost:8080/status | jq '.buffer'
   ```

3. **Reduce sampling frequency for non-critical metrics:**
   ```yaml
   sampling:
     statements: 60s  # Increase from 30s
     tables: 120s     # Increase from 60s
   ```

### High CPU usage

**Symptoms:**
- CPU consistently high
- Slow response times

**Solutions:**

1. **Check for query timeout issues:**
   ```bash
   grep "query timeout" /var/log/pg-collector/collector.log
   ```

2. **Reduce sampling frequency**

3. **Check PostgreSQL query performance:**
   ```sql
   SELECT * FROM pg_stat_statements
   WHERE query LIKE '%pg_stat%'
   ORDER BY total_time DESC;
   ```

---

## Service Issues

### Service won't start

**Symptoms:**
```
systemctl status pg-collector
● pg-collector.service - PostgreSQL Metrics Collector
   Active: failed
```

**Solutions:**

1. **Check logs:**
   ```bash
   sudo journalctl -u pg-collector -n 100 --no-pager
   ```

2. **Validate configuration:**
   ```bash
   pg-collector --config /etc/pg-collector/config.yaml --validate
   ```

3. **Check file permissions:**
   ```bash
   ls -la /etc/pg-collector/
   ls -la /var/lib/pg-collector/
   ```

4. **Run manually to see errors:**
   ```bash
   sudo -u pg-collector pg-collector --config /etc/pg-collector/config.yaml
   ```

### Service keeps restarting

**Symptoms:**
- Service restarts frequently
- Circuit breaker open

**Solutions:**

1. **Check for persistent connection issues**

2. **Review circuit breaker status:**
   ```bash
   curl http://localhost:8080/status | jq '.circuit_breakers'
   ```

3. **Check for resource exhaustion:**
   ```bash
   df -h /var/lib/pg-collector/
   free -m
   ```

---

## Health Check Issues

### Health endpoint returns unhealthy

**Symptoms:**
```json
{
  "status": "unhealthy",
  "postgres": "disconnected"
}
```

**Solutions:**

1. **Check component status:**
   ```bash
   curl http://localhost:8080/status | jq
   ```

2. **Identify failing component and address specific issue**

---

## Getting Help

If you're still having issues:

1. **Collect diagnostics:**
   ```bash
   pg-collector --config /etc/pg-collector/config.yaml --diagnostics > diag.txt
   ```

2. **Check logs:**
   ```bash
   sudo journalctl -u pg-collector --since "1 hour ago" > logs.txt
   ```

3. **Open an issue:** [GitHub Issues](https://github.com/burnside-project/pg-collector/issues)

4. **Contact support:** support@burnsideproject.ai

Include:
- PG Collector version: `pg-collector --version`
- PostgreSQL version
- Operating system
- Configuration (redact sensitive values)
- Error messages
- Steps to reproduce
