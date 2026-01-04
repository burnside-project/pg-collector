#!/bin/bash
#
# PG Collector Install Script
# https://github.com/burnside-project/pg-collector
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/burnside-project/pg-collector/main/scripts/install.sh | sudo bash
#   curl -sSL https://raw.githubusercontent.com/burnside-project/pg-collector/main/scripts/install.sh | sudo bash -s -- --version v1.0.0
#

set -e

REPO="burnside-project/pg-collector"
BINARY_NAME="pg-collector"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/pg-collector"
DATA_DIR="/var/lib/pg-collector"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
VERSION=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --version|-v)
      VERSION="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: install.sh [--version VERSION]"
      echo ""
      echo "Options:"
      echo "  --version, -v    Install specific version (e.g., v1.0.0)"
      echo "  --help, -h       Show this help"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Detect OS and architecture
detect_platform() {
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)

  case $ARCH in
    x86_64|amd64)
      ARCH="amd64"
      ;;
    aarch64|arm64)
      ARCH="arm64"
      ;;
    *)
      log_error "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac

  case $OS in
    linux)
      OS="linux"
      EXT="tar.gz"
      ;;
    darwin)
      OS="darwin"
      EXT="tar.gz"
      ;;
    mingw*|msys*|cygwin*|windows*)
      OS="windows"
      EXT="zip"
      ;;
    *)
      log_error "Unsupported operating system: $OS"
      exit 1
      ;;
  esac

  log_info "Detected platform: ${OS}-${ARCH}"
}

# Get latest version from GitHub
get_latest_version() {
  if [ -n "$VERSION" ]; then
    log_info "Using specified version: $VERSION"
    return
  fi

  log_info "Fetching latest version..."
  VERSION=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

  if [ -z "$VERSION" ]; then
    log_error "Failed to get latest version"
    exit 1
  fi

  log_info "Latest version: $VERSION"
}

# Download and install binary
install_binary() {
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}-${OS}-${ARCH}.${EXT}"
  TMP_DIR=$(mktemp -d)

  log_info "Downloading from: $DOWNLOAD_URL"

  if ! curl -sSL -o "${TMP_DIR}/${BINARY_NAME}.${EXT}" "$DOWNLOAD_URL"; then
    log_error "Failed to download binary"
    rm -rf "$TMP_DIR"
    exit 1
  fi

  log_info "Extracting..."
  cd "$TMP_DIR"

  if [ "$EXT" == "tar.gz" ]; then
    tar -xzf "${BINARY_NAME}.${EXT}"
  else
    unzip -q "${BINARY_NAME}.${EXT}"
  fi

  log_info "Installing to ${INSTALL_DIR}..."

  # Find the binary (might be pg-collector or pg-collector.exe)
  BINARY_FILE=$(find . -name "${BINARY_NAME}*" -type f ! -name "*.${EXT}" | head -1)

  if [ -z "$BINARY_FILE" ]; then
    log_error "Binary not found in archive"
    rm -rf "$TMP_DIR"
    exit 1
  fi

  chmod +x "$BINARY_FILE"
  mv "$BINARY_FILE" "${INSTALL_DIR}/${BINARY_NAME}"

  rm -rf "$TMP_DIR"

  log_info "Installed ${BINARY_NAME} to ${INSTALL_DIR}/${BINARY_NAME}"
}

# Create directories
create_directories() {
  log_info "Creating directories..."

  mkdir -p "$CONFIG_DIR"
  mkdir -p "$DATA_DIR"

  # Set permissions (Linux only)
  if [ "$OS" == "linux" ]; then
    if id "pg-collector" &>/dev/null; then
      chown pg-collector:pg-collector "$DATA_DIR"
    fi
  fi
}

# Create example config if not exists
create_example_config() {
  if [ -f "${CONFIG_DIR}/config.yaml" ]; then
    log_warn "Config file already exists: ${CONFIG_DIR}/config.yaml"
    return
  fi

  log_info "Creating example config..."

  cat > "${CONFIG_DIR}/config.yaml.example" << 'EOF'
# PG Collector Configuration
# Copy to config.yaml and customize

customer_id: "cust_your_id"
database_id: "db_prod_01"
database_name: "production"
tenant_tier: "starter"
output_mode: "s3_only"

postgres:
  conn_string: "postgres://pgcollector@localhost:5432/mydb?sslmode=verify-full"
  auth_method: cert
  tls:
    mode: verify-full
    ca_file: /etc/pg-collector/certs/ca.crt
    cert_file: /etc/pg-collector/certs/client.crt
    key_file: /etc/pg-collector/certs/client.key

s3:
  enabled: true
  region: "us-east-1"
  bucket: "your-metrics-bucket"
  key_prefix: "metrics"
  batch_interval: 5m
  format: "parquet"

sampling:
  activity: 1s
  database: 10s
  statements: 30s
  bgwriter: 10s
  replication: 1s
  vacuum: 30s
EOF

  log_info "Example config created: ${CONFIG_DIR}/config.yaml.example"
}

# Verify installation
verify_installation() {
  if ! command -v "${BINARY_NAME}" &> /dev/null; then
    # Try with full path
    if [ ! -x "${INSTALL_DIR}/${BINARY_NAME}" ]; then
      log_error "Installation verification failed"
      exit 1
    fi
  fi

  log_info "Verifying installation..."
  "${INSTALL_DIR}/${BINARY_NAME}" --version || true
}

# Print next steps
print_next_steps() {
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  PG Collector installed successfully!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "Next steps:"
  echo ""
  echo "  1. Copy and edit the config file:"
  echo "     sudo cp ${CONFIG_DIR}/config.yaml.example ${CONFIG_DIR}/config.yaml"
  echo "     sudo vi ${CONFIG_DIR}/config.yaml"
  echo ""
  echo "  2. Set up mTLS certificates (see documentation)"
  echo ""
  echo "  3. Start the collector:"
  echo "     pg-collector --config ${CONFIG_DIR}/config.yaml"
  echo ""
  echo "  4. (Optional) Install as systemd service:"
  echo "     See: https://github.com/burnside-project/pg-collector#systemd-service"
  echo ""
  echo "Documentation: https://github.com/burnside-project/pg-collector"
  echo ""
}

# Main
main() {
  log_info "PG Collector Installer"
  echo ""

  # Check if running as root (except on macOS for dev)
  if [ "$OS" != "darwin" ] && [ "$EUID" -ne 0 ]; then
    log_error "Please run as root: sudo bash install.sh"
    exit 1
  fi

  detect_platform
  get_latest_version
  install_binary
  create_directories
  create_example_config
  verify_installation
  print_next_steps
}

main "$@"
