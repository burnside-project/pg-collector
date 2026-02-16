# Troubleshooting Guide

Common issues and solutions for PG Collector.

## Quick Diagnostics

```bash
# Check service status
sudo systemctl status pg-collector

# View recent logs
sudo journalctl -u pg-collector -n 50

# Validate configuration
pg-collector --check-config --config /etc/pg-collector/config.yaml

# Check health endpoint
curl http://localhost:8080/health

# Check detailed status
curl http://localhost:8080/status
```

---

## Activation Issues

### Device Not Activated

**Symptoms:**
```
device not activated - add 'api_key' to config file
```

**Solution:**

Add your API key to the configuration file:

```yaml
api_key: "pgc_pro_abc123..."
```

Get your API key from the [Admin Console](https://dashboard.burnsideproject.ai).

---

### Activation Failed

**Symptoms:**
```
activation failed: invalid API key
```

**Solutions:**

1. **Verify API key format** - should start with `pgc_`
2. **Check API key is active** - not expired or revoked
3. **Check network connectivity** to Key Service

---

### Device Revoked

**Symptoms:**
```
device has been revoked
```

**Solution:**

Contact your administrator to re-enable or generate a new API key.

To reset local state:
```bash
pg-collector --deactivate
```

---

## Connection Issues

### Cannot Connect to PostgreSQL

**Symptoms:**
```
ERROR: connection refused
ERROR: connection timed out
```

**Solutions:**

1. **Check network connectivity:**
   ```bash
   nc -zv db.burnsideproject.ai 5432
   ```

2. **Check PostgreSQL is listening:**
   ```bash
   sudo ss -tlnp | grep 5432
   ```

3. **Check pg_hba.conf allows connection:**
   ```
   hostssl all pgcollector YOUR_IP/32 cert
   ```

4. **Check firewall rules**

---

### Certificate Authentication Failed

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
   psql "host=db.burnsideproject.ai port=5432 dbname=postgres user=pgcollector \
     sslmode=verify-full \
     sslcert=/etc/pg-collector/certs/client.crt \
     sslkey=/etc/pg-collector/certs/client.key \
     sslrootcert=/etc/pg-collector/certs/ca.crt"
   ```

---

### AWS IAM Authentication Failed

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
   SELECT rolname FROM pg_roles WHERE rolname = 'pgcollector';
   ```

3. **Check IAM policy resource ARN** - Region, Account ID, DBI resource ID correct?

---

## Service Issues

### Service Won't Start

**Symptoms:**
```
systemctl status pg-collector
● pg-collector.service
   Active: failed
```

**Solutions:**

1. **Check logs:**
   ```bash
   sudo journalctl -u pg-collector -n 100 --no-pager
   ```

2. **Validate configuration:**
   ```bash
   pg-collector --check-config --config /etc/pg-collector/config.yaml
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

---

### High Resource Usage

**Memory:**
- Check configured buffer limits
- Reduce sampling frequency

**CPU:**
- Reduce sampling frequency
- Check for output backpressure

---

## Health Check Issues

### Health Endpoint Returns Degraded

**Symptoms:**
```json
{
  "status": "degraded",
  "components": {
    "postgres": {"status": "down"}
  }
}
```

**Solutions:**

1. **Check detailed status:**
   ```bash
   curl http://localhost:8080/status | jq
   ```

2. **Check PostgreSQL connectivity**

3. **Check logs for specific errors**

---

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `device not activated` | Missing api_key | Add api_key to config |
| `connection refused` | PostgreSQL not reachable | Check network/firewall |
| `certificate verify failed` | Wrong CA certificate | Use correct ca.crt |
| `authentication failed` | Wrong auth method | Check auth_method config |
| `permission denied` | Missing grants | Grant pg_monitor role |
| `timeout` | Query too slow | Increase query_timeout |
| `grace period expired` | Offline too long | Restore network to Key Service |

---

## Getting Help

If you're still having issues:

1. **Check version:**
   ```bash
   pg-collector --version
   ```

2. **Check logs:**
   ```bash
   sudo journalctl -u pg-collector --since "1 hour ago"
   ```

3. **Open an issue:** [GitHub Issues](https://github.com/burnside-project/pg-collector/issues)

4. **Contact support:** support@burnsideproject.ai

Include:
- PG Collector version
- PostgreSQL version
- Operating system
- Configuration (redact api_key)
- Error messages
- Steps to reproduce
