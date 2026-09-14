#!/usr/bin/env bash
#
# Generates a random JWT secret for OnlyOffice and writes a ready-to-paste
# compose/onlyoffice.generated.yml with the secret filled in (git-ignored).
# The original compose/onlyoffice.yml is left untouched. Re-run to rotate
# the secret.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../compose/onlyoffice.yml"
OUTPUT_FILE="$SCRIPT_DIR/../compose/onlyoffice.generated.yml"

if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: openssl is required. Run ./scripts/install-prereqs.sh first." >&2
  exit 1
fi

SECRET="$(openssl rand -hex 32)"

sed "s/\${JWT_SECRET}/$SECRET/" "$TEMPLATE_FILE" > "$OUTPUT_FILE"
chmod 600 "$OUTPUT_FILE"

echo "Generated JWT secret and wrote $OUTPUT_FILE (compose/onlyoffice.yml was not modified)."
echo
echo "JWT_SECRET=$SECRET"
echo
echo "Paste onlyoffice.generated.yml into the Dokploy compose deployment, then use the same secret as the Secret key in Nextcloud's ONLYOFFICE settings."
