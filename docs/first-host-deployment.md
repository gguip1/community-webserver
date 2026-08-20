# First host deployment checklist

This document defines the M0 acceptance path. It is deliberately limited to proving one production deployment; backup automation, SSR, image optimization, and automatic promotion are not M0 blockers.

## Prerequisites

- [ ] A domain is selected and DNS reaches the host, or a Tunnel alternative is approved.
- [ ] The host can receive public 80/443 traffic for Caddy TLS, or the chosen ingress documents an equivalent path.
- [ ] `/etc/wepick/prod.env` exists, is owned by `wepick-deploy`, and has mode `600`.
- [ ] FE and BE CI publish approved immutable GHCR tags.
- [ ] The production self-hosted runner is registered with `self-hosted`, `linux`, and `wepick-prod` labels.
- [ ] The GitHub `production` Environment protects manual deployment and stores only `GHCR_PULL_TOKEN`.

## Service topology

```text
Internet
  └─ Caddy :80/:443
      ├─ /api/*     → backend:8080
      ├─ /uploads/* → uploads_data volume (read-only)
      └─ /*         → frontend:3000

backend
  ├─ mysql:3306 (internal only)
  └─ uploads_data:/data/uploads
```

Only Caddy publishes host ports. Backend and MySQL must not publish host ports.

## Deployment command

The host runner executes:

```bash
./scripts/deploy-host.sh /etc/wepick/prod.env
```

The workflow copies the host runtime file to a temporary file and appends the approved `FE_IMAGE_TAG` and `BE_IMAGE_TAG` inputs before executing the script. It validates Compose, pulls the immutable images, starts services, and checks `backend:/actuator/health`.

## Production smoke test

After deployment, verify through the production domain:

- [ ] `https://<domain>/api/actuator/health` returns `UP`.
- [ ] frontend health and primary pages load over HTTPS.
- [ ] register, login, logout, and session persistence work.
- [ ] a topic can be read and a vote can be submitted once seed/admin setup exists.
- [ ] create a post with a PNG/JPEG/GIF/WebP upload.
- [ ] uploaded image URL under `/uploads/...` returns the original image through Caddy.
- [ ] profile image upload and display work.

Record failures as child issues of the M0 Epic rather than expanding this checklist indefinitely.

## Data safety

- Never use `docker compose down -v` against production.
- `wepick_mysql_data` and `wepick_uploads_data` are persistent named volumes.
- Initial deployment accepts the absence of automated off-host backup; backup and restore rehearsal are tracked separately in M2.
