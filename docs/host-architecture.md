# Host deployment architecture

## Active target

A single host runs Caddy, frontend, backend, and MySQL through Docker Compose. Caddy owns the public 80/443 ingress and automatic TLS for the application domain. A self-hosted GitHub Actions runner executes production CD locally; it is not publicly exposed and requires no server SSH key in GitHub.

## Delivery boundaries

- `wepick-fe` and `wepick-be`: GitHub-hosted Actions CI tests and publishes immutable GHCR images.
- `wepick-infra`: declares the runtime topology, deployment/rollback scripts, and self-hosted runner CD workflow.
- The production host: pulls already-built images and never builds application source.
- The production runner executes commands as the dedicated `wepick-deploy` Linux account. It must only accept protected `main`/manual infra deployment jobs, never fork or arbitrary PR jobs. Docker access makes this account effectively host-privileged.

## CD flow

1. FE/BE CI publishes a commit-SHA image to GHCR.
2. An operator dispatches `Host production deploy` in this repository with the approved FE and BE image tags.
3. The self-hosted runner combines those tags with `/etc/wepick/prod.env`, then executes `scripts/deploy-host.sh` locally.
4. Compose pulls immutable images, restarts services, and verifies `/actuator/health`.
5. Rollback dispatch uses the previously known-good tags.

## Deferred decisions

- Public reachability: direct 80/443 port forwarding versus Cloudflare Tunnel.
- Automatic promotion: begin with protected manual dispatch; add an approved image-promotion manifest or repository dispatch only after the initial deployment path is exercised.
- Local image storage is now the active target: backend writes to the named `uploads_data` volume at `/data/uploads`; Caddy mounts it read-only at `/srv/uploads` and serves `/uploads/*`. The future S3/MinIO decision is isolated behind the backend `ImageStorage` interface.
- Automated off-host MySQL backups are intentionally deferred, but `wepick_mysql_data` must never be removed by deployment commands.

## Runtime environment contract

The host owns `/etc/wepick/prod.env` with mode `600`, owned by `wepick-deploy`. It is passed to Compose using `--env-file`; only variable names and placeholders belong in Git.

```env
DOMAIN_NAME=wepick.example.com
ACME_EMAIL=admin@example.com
FE_IMAGE=ghcr.io/w-gain/wepick-fe
BE_IMAGE=ghcr.io/w-gain/wepick-be
MYSQL_DATABASE=wepick
MYSQL_USER=wepick
MYSQL_PASSWORD=replace-with-real-secret
MYSQL_ROOT_PASSWORD=replace-with-different-real-secret
SESSION_COOKIE_SAME_SITE=lax
```

`FE_IMAGE_TAG` and `BE_IMAGE_TAG` are immutable deployment inputs added by the protected deployment workflow. `GHCR_PULL_TOKEN` is a GitHub `production` Environment secret, not a host runtime variable. The Compose file injects `IMAGE_STORAGE_LOCAL_ROOT=/data/uploads` and `IMAGE_PUBLIC_PREFIX=/uploads` into backend; they are stable topology values rather than secrets.

## AWS status

Existing Terraform, EC2, ECR, SSM, and S3-artifact delivery files are retained as manual-only legacy AWS assets. They are not the target for host deployment.
