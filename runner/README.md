# Self-hosted Actions runner for production CD

The runner executes only trusted Wepick infrastructure deployment jobs on the production host. FE and BE CI remain on GitHub-hosted runners.

## Security boundary

- Register a dedicated runner group such as `wepick-production` and give it only this repository.
- Use the `wepick-prod` label in addition to `self-hosted` and `linux`.
- Restrict the group to protected `main` and manually dispatched production workflows. Never use this runner for fork PRs or arbitrary PR CI.
- Run the runner as a dedicated non-login Linux user such as `wepick-deploy`. Workflow commands run with this Linux account, not as root.
- Docker group membership is effectively host-privileged; allow only protected `main` and approved manual deployment workflows to reach this runner.
- Do not expose a runner port. The runner polls GitHub over outbound HTTPS.
- Protect the `production` GitHub Environment with required reviewers before placing a GHCR pull token there.

## Host runtime file

Create `/etc/wepick/prod.env` with `wepick-deploy:wepick-deploy` ownership and mode `600`. It contains only runtime secrets and stable values, not image tags:

```env
DOMAIN_NAME=wepick.example.com
ACME_EMAIL=admin@example.com
FE_IMAGE=ghcr.io/w-gain/wepick-fe
BE_IMAGE=ghcr.io/w-gain/wepick-be
MYSQL_DATABASE=wepick
MYSQL_USER=wepick
MYSQL_PASSWORD=replace-with-real-secret
MYSQL_ROOT_PASSWORD=replace-with-real-secret
SESSION_COOKIE_SAME_SITE=lax
```

The CD workflow supplies immutable `FE_IMAGE_TAG` and `BE_IMAGE_TAG` as protected manual-dispatch inputs. Do not commit `/etc/wepick/prod.env`.

## Bootstrap

Install the official GitHub Actions runner on the host only after the repository runner group and labels are configured in GitHub. The actual registration token is short-lived and must not be committed or placed in this repository.
