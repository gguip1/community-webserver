#!/usr/bin/env bash
# Roll back by supplying a previously committed environment file with known-good image tags.
set -euo pipefail
exec "$(dirname "$0")/deploy-host.sh" "${1:?Usage: scripts/rollback-host.sh <previous environment .env path>}"
