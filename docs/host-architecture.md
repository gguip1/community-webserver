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
- Local image storage requires backend support; the current backend still implements S3 presigned uploads and cannot be switched by Compose alone.
- Automated off-host MySQL backups are intentionally deferred, but `wepick_mysql_data` must never be removed by deployment commands.

## AWS status

Existing Terraform, EC2, ECR, SSM, and S3-artifact delivery files are retained as manual-only legacy AWS assets. They are not the target for host deployment.
