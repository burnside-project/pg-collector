# Installation Guide

**Get PG Collector running in minutes.** Detailed installation instructions for all platforms.

## System Requirements

- **OS:** Linux (amd64, arm64), macOS (Intel, Apple Silicon), Windows (amd64)
- **PostgreSQL:** Version 12 or later
- **Memory:** 64MB minimum, 128MB recommended
- **Disk:** 100MB for binary + buffer space

---

## Linux Installation

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/burnside-project/pg-collector/main/scripts/install.sh | sudo bash
```

This script:
- Detects your architecture
- Downloads the latest release
- Installs to `/usr/local/bin/`
- Creates system user `pg-collector`
- Sets up directory structure

### Manual Installation

```bash
# Download (choose your architecture)
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64.tar.gz

# Extract
tar -xzf pg-collector-linux-amd64.tar.gz

# Install binary
sudo mv pg-collector /usr/local/bin/
sudo chmod +x /usr/local/bin/pg-collector

# Create system user
sudo useradd --system --no-create-home --shell /sbin/nologin pg-collector

# Create directories
sudo mkdir -p /etc/pg-collector/certs
sudo mkdir -p /var/lib/pg-collector

# Set ownership
sudo chown -R pg-collector:pg-collector /var/lib/pg-collector
```

### Verify Installation

```bash
pg-collector --version
```

---

## macOS Installation

### Intel Mac

```bash
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-amd64.tar.gz
tar -xzf pg-collector-darwin-amd64.tar.gz
sudo mv pg-collector /usr/local/bin/
```

### Apple Silicon (M1/M2/M3)

```bash
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-arm64.tar.gz
tar -xzf pg-collector-darwin-arm64.tar.gz
sudo mv pg-collector /usr/local/bin/
```

### Directory Setup

```bash
sudo mkdir -p /etc/pg-collector/certs
sudo mkdir -p /var/lib/pg-collector
```

---

## Windows Installation

### PowerShell

```powershell
# Download
Invoke-WebRequest -Uri "https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-windows-amd64.zip" -OutFile "pg-collector.zip"

# Extract
Expand-Archive -Path "pg-collector.zip" -DestinationPath "C:\Program Files\pg-collector"

# Add to PATH (run as Administrator)
$env:Path += ";C:\Program Files\pg-collector"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
```

### Verify

```powershell
pg-collector --version
```

---

## Docker Installation

### Run Container

```bash
docker run -d \
  --name pg-collector \
  -v /etc/pg-collector:/etc/pg-collector:ro \
  -v /var/lib/pg-collector:/var/lib/pg-collector \
  -p 8080:8080 \
  ghcr.io/burnside-project/pg-collector:latest \
  --config /etc/pg-collector/config.yaml
```

### Docker Compose

```yaml
version: '3.8'
services:
  pg-collector:
    image: ghcr.io/burnside-project/pg-collector:latest
    restart: unless-stopped
    volumes:
      - ./config.yaml:/etc/pg-collector/config.yaml:ro
      - ./certs:/etc/pg-collector/certs:ro
      - collector-data:/var/lib/pg-collector
    ports:
      - "8080:8080"
    command: --config /etc/pg-collector/config.yaml

volumes:
  collector-data:
```

---

## Verify Download

All releases include SHA256 checksums:

```bash
# Download checksums
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/checksums.txt

# Verify
sha256sum -c checksums.txt --ignore-missing
```

---

## Demo Build Installation

**Want to try it first?** The demo build lets you evaluate PG Collector without certificate setup—just point it at your database and go.

### Download Demo Build

| Platform | Download |
|----------|----------|
| Linux amd64 | `pg-collector-linux-amd64-demo.tar.gz` |
| Linux arm64 | `pg-collector-linux-arm64-demo.tar.gz` |
| macOS Intel | `pg-collector-darwin-amd64-demo.tar.gz` |
| macOS Apple Silicon | `pg-collector-darwin-arm64-demo.tar.gz` |

```bash
# Example: Linux amd64
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-linux-amd64-demo.tar.gz
tar -xzf pg-collector-linux-amd64-demo.tar.gz

# macOS Apple Silicon
curl -LO https://github.com/burnside-project/pg-collector/releases/latest/download/pg-collector-darwin-arm64-demo.tar.gz
tar -xzf pg-collector-darwin-arm64-demo.tar.gz
```

### Demo Configuration

```yaml
# demo-config.yaml
databases:
  - name: local
    postgres:
      conn_string: "postgres://user:password@localhost:5432/postgres"
      auth_method: password  # Only in demo builds

local:
  enabled: true
  path: ./output
  format: jsonl
```

### Run Demo

```bash
./pg-collector-demo --config demo-config.yaml
```

Metrics are written to the `./output` directory.

### Demo Limitations

| Feature | Demo | Production |
|---------|------|------------|
| Password auth | Allowed | Not supported |
| mTLS/IAM auth | Supported | Required |
| Local output | Yes | Yes |
| S3 output | Yes | Yes |
| Platform output | No | Yes |

For production, use the standard installation with mTLS or IAM authentication.

---

## Directory Structure

After installation:

```
/usr/local/bin/
└── pg-collector          # Binary

/etc/pg-collector/
├── config.yaml           # Configuration
└── certs/
    ├── ca.crt            # CA certificate
    ├── client.crt        # Client certificate
    └── client.key        # Client private key

/var/lib/pg-collector/
└── buffer.db             # Local buffer (auto-created)
```

---

## Running as a Service

For production deployments, run PG Collector as a system service with **self-healing** capabilities. The service will automatically restart if it crashes and start at system boot.

### Linux (systemd)

```bash
# Create service file
sudo cat > /etc/systemd/system/pg-collector.service << 'EOF'
[Unit]
Description=PostgreSQL Metrics Collector
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=pg-collector
Group=pg-collector
WorkingDirectory=/var/lib/pg-collector
ExecStart=/usr/local/bin/pg-collector --config /etc/pg-collector/config.yaml

# Self-healing
Restart=always
RestartSec=5
WatchdogSec=60

# Resource limits
MemoryMax=512M
CPUQuota=50%

# Logging
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable pg-collector
sudo systemctl start pg-collector

# Check status
sudo systemctl status pg-collector
```

**Self-Healing Features:**
- `Restart=always` - Automatically restarts on any failure
- `RestartSec=5` - Waits 5 seconds before restart
- `WatchdogSec=60` - systemd kills if no heartbeat in 60s
- `MemoryMax=512M` - Prevents memory leaks from affecting system

### macOS (launchd)

```bash
# Create launch daemon
sudo cat > /Library/LaunchDaemons/com.burnsideproject.pg-collector.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.burnsideproject.pg-collector</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/pg-collector</string>
        <string>--config</string>
        <string>/etc/pg-collector/config.yaml</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/pg-collector/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/pg-collector/stderr.log</string>
</dict>
</plist>
EOF

# Create directories
sudo mkdir -p /var/log/pg-collector

# Load and start
sudo launchctl load /Library/LaunchDaemons/com.burnsideproject.pg-collector.plist

# Check status
sudo launchctl list | grep pg-collector
```

**Self-Healing Features:**
- `KeepAlive=true` - Automatically restarts on any failure
- `ThrottleInterval=5` - Minimum 5 seconds between restarts
- `RunAtLoad=true` - Starts at system boot

### Windows (NSSM)

Use [NSSM](https://nssm.cc/) for reliable Windows service management:

```powershell
# Download NSSM
Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "nssm.zip"
Expand-Archive -Path "nssm.zip" -DestinationPath "C:\Tools"

# Install as service
C:\Tools\nssm-2.24\win64\nssm.exe install pg-collector "C:\Program Files\pg-collector\pg-collector.exe"
C:\Tools\nssm-2.24\win64\nssm.exe set pg-collector AppParameters "--config C:\ProgramData\pg-collector\config.yaml"

# Self-healing settings
C:\Tools\nssm-2.24\win64\nssm.exe set pg-collector AppExit Default Restart
C:\Tools\nssm-2.24\win64\nssm.exe set pg-collector AppRestartDelay 5000

# Logging
C:\Tools\nssm-2.24\win64\nssm.exe set pg-collector AppStdout "C:\ProgramData\pg-collector\logs\stdout.log"
C:\Tools\nssm-2.24\win64\nssm.exe set pg-collector AppStderr "C:\ProgramData\pg-collector\logs\stderr.log"

# Start service
C:\Tools\nssm-2.24\win64\nssm.exe start pg-collector
```

**Alternative (native sc.exe):**

```powershell
# Create service
sc.exe create pg-collector binPath= "C:\Program Files\pg-collector\pg-collector.exe --config C:\ProgramData\pg-collector\config.yaml" start= auto

# Configure self-healing (restart on failure)
sc.exe failure pg-collector reset= 86400 actions= restart/5000/restart/5000/restart/30000

# Start
sc.exe start pg-collector
```

### Service Management Quick Reference

| Action | Linux | macOS | Windows |
|--------|-------|-------|---------|
| **Start** | `sudo systemctl start pg-collector` | `sudo launchctl start com.burnsideproject.pg-collector` | `sc.exe start pg-collector` |
| **Stop** | `sudo systemctl stop pg-collector` | `sudo launchctl stop com.burnsideproject.pg-collector` | `sc.exe stop pg-collector` |
| **Status** | `sudo systemctl status pg-collector` | `sudo launchctl list \| grep pg-collector` | `sc.exe query pg-collector` |
| **Logs** | `journalctl -u pg-collector -f` | `tail -f /var/log/pg-collector/stdout.log` | `Get-Content logs\stdout.log -Tail 50 -Wait` |
| **Restart** | `sudo systemctl restart pg-collector` | Unload then load plist | `sc.exe stop pg-collector && sc.exe start pg-collector` |

### Health Check

All platforms support HTTP health checks:

```bash
curl http://localhost:8080/health
# {"status":"ok","components":{"postgres":{"status":"ok"}},"timestamp":"..."}
```

---

## Uninstallation

### Linux

```bash
sudo systemctl stop pg-collector
sudo systemctl disable pg-collector
sudo rm /etc/systemd/system/pg-collector.service
sudo systemctl daemon-reload
sudo rm /usr/local/bin/pg-collector
sudo rm -rf /etc/pg-collector
sudo rm -rf /var/lib/pg-collector
sudo userdel pg-collector
```

### macOS

```bash
sudo launchctl unload /Library/LaunchDaemons/com.burnsideproject.pg-collector.plist
sudo rm /Library/LaunchDaemons/com.burnsideproject.pg-collector.plist
sudo rm /usr/local/bin/pg-collector
sudo rm -rf /etc/pg-collector
sudo rm -rf /var/lib/pg-collector
sudo rm -rf /var/log/pg-collector
```

### Windows

```powershell
# With NSSM
C:\Tools\nssm-2.24\win64\nssm.exe stop pg-collector
C:\Tools\nssm-2.24\win64\nssm.exe remove pg-collector confirm

# Or with sc.exe
sc.exe stop pg-collector
sc.exe delete pg-collector

# Remove files
Remove-Item -Recurse -Force "C:\Program Files\pg-collector"
Remove-Item -Recurse -Force "C:\ProgramData\pg-collector"
```

### Docker

```bash
docker stop pg-collector
docker rm pg-collector
docker rmi ghcr.io/burnside-project/pg-collector:latest
```

---

## Next Steps

- [Quick Start](quick-start.md) - Get running quickly
- [Configuration](configuration.md) - Configure for your environment
- [Security](security.md) - Set up certificates
