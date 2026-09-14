#!/usr/bin/env bash
#
# Configures ufw to allow exactly the ports SelfCloud needs:
#   - SSH                      (so you don't get locked out)
#   - Dokploy dashboard        3000/tcp
#   - Traefik HTTP/HTTPS       80/tcp, 443/tcp   (Dokploy's reverse proxy)
#   - Nextcloud                8080/tcp
#   - OnlyOffice               8088/tcp
#
# Safe to re-run: skips any rule that's already active.

set -euo pipefail

log()  { printf '\n\033[1;32m[configure-firewall]\033[0m %s\n' "$1"; }
err()  { printf '\n\033[1;31m[configure-firewall]\033[0m %s\n' "$1" >&2; }

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

if ! command -v ufw >/dev/null 2>&1; then
  if [[ -r /etc/os-release ]] && grep -qiE '^ID(_LIKE)?=.*(ubuntu|debian)' /etc/os-release; then
    log "ufw not found. Installing..."
    $SUDO apt-get update -y
    $SUDO apt-get install -y ufw
  else
    err "ufw not found and this doesn't look like a Debian/Ubuntu host. Install ufw manually, or use your distro's firewall tool (e.g. firewalld)."
    exit 1
  fi
fi

# port/proto:comment
RULES=(
  "22/tcp:SSH"
  "3000/tcp:Dokploy dashboard"
  "80/tcp:HTTP (Traefik)"
  "443/tcp:HTTPS (Traefik)"
  "8080/tcp:Nextcloud"
  "8088/tcp:OnlyOffice"
)

for rule in "${RULES[@]}"; do
  port_proto="${rule%%:*}"
  comment="${rule##*:}"
  if $SUDO ufw status | grep -qE "^${port_proto//\//\\/}[[:space:]]+ALLOW"; then
    log "Already allowed: $port_proto ($comment)"
  else
    log "Allowing $port_proto ($comment)"
    $SUDO ufw allow "$port_proto" comment "$comment"
  fi
done

if $SUDO ufw status | grep -q "Status: active"; then
  log "ufw already active."
else
  log "Enabling ufw..."
  $SUDO ufw --force enable
fi

log "Current firewall status:"
$SUDO ufw status verbose
