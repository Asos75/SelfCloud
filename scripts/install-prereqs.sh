#!/usr/bin/env bash
#
# Installs everything SelfCloud needs on a fresh Linux host:
#   - base dependencies (curl, ca-certificates, gnupg)
#   - Docker Engine + the Compose plugin
#   - Dokploy
#
# Safe to re-run: every step checks whether it's already done before acting.

set -euo pipefail

log()  { printf '\n\033[1;32m[install-prereqs]\033[0m %s\n' "$1"; }
warn() { printf '\n\033[1;33m[install-prereqs]\033[0m %s\n' "$1"; }
err()  { printf '\n\033[1;31m[install-prereqs]\033[0m %s\n' "$1" >&2; }

if [[ "$(uname -s)" != "Linux" ]]; then
  err "This script only supports Linux hosts (found $(uname -s))."
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    err "This script must be run as root, or with sudo available."
    exit 1
  fi
else
  SUDO=""
fi

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="${ID:-unknown}"
else
  OS_ID="unknown"
fi

# --- base dependencies ------------------------------------------------------

install_base_deps() {
  local missing=()
  for pkg_cmd in "curl:curl" "gnupg:gpg" "ca-certificates:update-ca-certificates"; do
    local pkg="${pkg_cmd%%:*}"
    local cmd="${pkg_cmd##*:}"
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$pkg")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    log "Base dependencies already installed."
    return
  fi

  log "Installing missing base dependencies: ${missing[*]}"
  case "$OS_ID" in
    ubuntu|debian)
      $SUDO apt-get update -y
      $SUDO apt-get install -y "${missing[@]}"
      ;;
    centos|rhel|fedora|rocky|almalinux)
      $SUDO dnf install -y "${missing[@]}" 2>/dev/null || $SUDO yum install -y "${missing[@]}"
      ;;
    *)
      err "Unsupported distro '$OS_ID'. Install manually: ${missing[*]}"
      exit 1
      ;;
  esac
}

# --- docker ------------------------------------------------------------------

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed ($(docker --version))."
  else
    log "Docker not found. Installing via get.docker.com convenience script..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    $SUDO sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
  fi

  if ! docker compose version >/dev/null 2>&1; then
    err "Docker Compose plugin missing after install; check your Docker installation."
    exit 1
  else
    log "Docker Compose plugin present ($(docker compose version --short 2>/dev/null))."
  fi

  $SUDO systemctl enable --now docker >/dev/null 2>&1 || true

  if [[ -n "${SUDO_USER:-}" ]] && ! id -nG "$SUDO_USER" | grep -qw docker; then
    log "Adding user '$SUDO_USER' to the docker group (log out/in for it to take effect)."
    $SUDO usermod -aG docker "$SUDO_USER"
  fi
}

# --- dokploy -------------------------------------------------------------

install_dokploy() {
  if command -v docker >/dev/null 2>&1 && $SUDO docker service ls --format '{{.Name}}' 2>/dev/null | grep -qx "dokploy"; then
    log "Dokploy already installed."
    return
  fi

  log "Dokploy not found. Installing via dokploy.com install script..."
  curl -fsSL https://dokploy.com/install.sh | $SUDO sh
}

install_base_deps
install_docker
install_dokploy

log "All prerequisites are installed."
