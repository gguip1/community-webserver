# wepick-infra

Wepick의 단일 운영 저장소입니다. 프론트엔드와 백엔드는 각자 CI로 테스트된 불변 이미지를 GHCR에 발행하고, 이 저장소가 해당 이미지의 운영 승격, 호스트 런타임, Jenkins CD를 관리합니다.

## 현재 운영 목표

```text
GitHub Actions (FE/BE CI) → GHCR immutable images
                              ↓
wepick-infra promotion manifest → Jenkins CD → Docker Compose host
                                              ├─ Caddy (80/443, automatic TLS)
                                              ├─ frontend
                                              ├─ backend
                                              └─ MySQL named volume
```

- 운영 런타임: 단일 Docker host
- 프록시: Caddy
- 이미지 registry: GHCR
- CD control plane: self-hosted Jenkins (localhost only)
- 비밀값: 초기에는 Jenkins Credentials와 호스트의 미추적 environment file, 추후 HashiCorp Vault 검토
- 데이터베이스: infra Compose가 독립 MySQL service와 named volume을 소유

## Layout

| Path | Purpose |
|---|---|
| `compose/prod` | Caddy, frontend, backend, MySQL production topology |
| `compose/platform` | Jenkins control-plane topology |
| `caddy` | Public routing and TLS configuration |
| `environments/prod` | Versioned image-promotion template; real `.env` stays untracked |
| `scripts` | Host deployment and rollback commands |
| `jenkins` | Jenkins security boundary and bootstrap notes |
| `docs/host-architecture.md` | Current host deployment decisions and deferred work |
| `terraform`, `docker`, `nginx`, legacy workflows | Historical AWS deployment assets; not the host deployment target |

## Validation

```bash
docker compose --env-file environments/prod/.env.example -f compose/prod/docker-compose.yml config -q
docker compose -f compose/platform/docker-compose.yml config -q
docker run --rm -e DOMAIN_NAME=wepick.example.com -e ACME_EMAIL=admin@example.com \
  -v "$PWD/caddy/Caddyfile:/etc/caddy/Caddyfile:ro" \
  caddy:2.10-alpine caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
```

## AWS legacy

AWS resources are not destroyed in this branch. Terraform, EC2/SSM/ECR delivery scripts, and existing AWS workflows remain preserved for historical reference until the host deployment path is accepted and exercised.
