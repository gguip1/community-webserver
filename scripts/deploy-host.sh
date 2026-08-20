#!/usr/bin/env bash
# Execute on the production host via a restricted deploy user.
# Usage: scripts/deploy-host.sh environments/prod/.env
set -euo pipefail

ENV_FILE=${1:?Usage: scripts/deploy-host.sh <environment .env path>}
COMPOSE_FILE=compose/prod/docker-compose.yml

[[ -f "$ENV_FILE" ]] || { echo "Missing environment file: $ENV_FILE" >&2; exit 1; }

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config -q
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --remove-orphans

echo "Waiting for backend health endpoint..."
for attempt in $(seq 1 30); do
  if docker exec wepick_backend wget -qO- http://localhost:8080/actuator/health >/dev/null 2>&1; then
    echo "Deployment healthy (attempt $attempt)."
    exit 0
  fi
  sleep 2
done

echo "Backend health check failed. Do not consider this deployment promoted." >&2
exit 1
