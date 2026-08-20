# Host deployment architecture

## Active target

A single host runs Caddy, frontend, backend, and MySQL through Docker Compose. Caddy owns the public 80/443 ingress and automatic TLS for the application domain. Jenkins is a local-only control plane bound to `127.0.0.1:8080`.

## Delivery boundaries

- `wepick-fe` and `wepick-be`: CI tests and publish immutable GHCR images.
- `wepick-infra`: declares the promoted image tags, runtime topology, deployment/rollback scripts, and Jenkins CD.
- The production host: pulls already-built images and never builds application source.

## Deferred decisions

- Public reachability: direct 80/443 port forwarding versus Cloudflare Tunnel.
- Jenkins trigger: GitHub webhook versus controlled polling.
- Local image storage requires backend support; the current backend still implements S3 presigned uploads and cannot be switched by Compose alone.
- Automated off-host MySQL backups are intentionally deferred, but `wepick_mysql_data` must never be removed by deployment commands.

## AWS status

Existing Terraform, EC2, ECR, SSM, and S3-artifact delivery files are retained as legacy AWS assets. They are not the target for the host deployment foundation.
