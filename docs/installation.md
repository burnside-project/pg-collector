# Installation Guide

Detailed installation instructions for all platforms.

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

## Uninstallation

### Linux

```bash
sudo systemctl stop pg-collector
sudo systemctl disable pg-collector
sudo rm /etc/systemd/system/pg-collector.service
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
