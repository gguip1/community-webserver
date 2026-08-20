# Jenkins CD foundation

Jenkins owns production deployment. FE and BE repositories only test and publish immutable images to GHCR.

## Security boundary

- Jenkins is bound to `127.0.0.1:8080`; do not expose it through the public Caddy site.
- Access the UI through an SSH tunnel: `ssh -L 8080:127.0.0.1:8080 <host>`.
- Do not mount `/var/run/docker.sock` into Jenkins. The deployment pipeline should SSH to a narrowly-permitted host deploy user and call `scripts/deploy-host.sh`.
- GitHub Actions secrets are unavailable to Jenkins. Store Jenkins-only credentials in the Jenkins Credentials store initially; migrate to HashiCorp Vault later.

## Required Jenkins credentials

1. GitHub deploy key or GitHub App credential with read access to `W-Gain/wepick-infra`.
2. Read-only GHCR token for `ghcr.io/w-gain/wepick-fe` and `ghcr.io/w-gain/wepick-be` if packages are private.
3. SSH private key for the server deploy user.

## Initial setup (not executed by this repository)

```bash
docker compose -f compose/platform/docker-compose.yml up -d
docker exec wepick_jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

The Jenkinsfile and credentials configuration are intentionally added only after the GitHub trigger and host deploy-user model are chosen.
