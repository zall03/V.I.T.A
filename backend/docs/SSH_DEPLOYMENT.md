# Automatic development deployment over SSH

Push to main runs Go build/vet/unit/integration tests with disposable PostgreSQL and
Python tests. Deployment only runs after tests pass. Actions pinned by commit.
Manual workflow dispatch also deploys main only. No production environment configured.

GitHub repository Actions variables: DEPLOY_HOST, DEPLOY_USER (azureuser),
DEPLOY_PORT (22), DEPLOY_PATH (/opt/vita).
Secrets: DEPLOY_SSH_KEY (dedicated private key), DEPLOY_KNOWN_HOSTS (verified host key).
Configure under Settings > Secrets and variables > Actions. The deploy job does not
reference a GitHub Environment; environment approvals/protection rules do not apply.
Install corresponding public key in server user's ~/.ssh/authorized_keys. Verify SSH
host fingerprints using Azure console/trusted channel before storing known_hosts.
Do not disable host verification. Server requires Docker Compose v2 with --wait,
GitHub runner SSH reachability, bash, tar, curl, and Docker access for deployment user.

One-time setup on server:
```sh
mkdir -p /opt/vita/shared
chmod 700 /opt/vita/shared
nano /opt/vita/shared/backend.env
chmod 600 /opt/vita/shared/backend.env
```
Use backend/.env.example contents. Set POSTGRES_PASSWORD, JWT_SECRET, AI_SERVICE_TOKEN,
seed credentials and CORS. Keep APP_ENV=development, AI_PROVIDER=mock and external AI
disabled for synthetic testing. Code releases do not overwrite this file.

Each commit is extracted into /opt/vita/releases/<commit>. /opt/vita/current points
to last successfully checked release. Stable Compose project `vita` preserves volumes.
If existing containers use another project name, plan volume migration separately;
do not assume existing `backend_postgres_data` becomes `vita_postgres_data`.

After first successful deployment, bootstrap once:
```sh
cd /opt/vita/current/backend
docker compose -p vita --profile tools run --rm seed
docker compose -p vita ps -a
docker compose -p vita logs --tail=100 api worker ai-service
```
API remains loopback-only; configure HTTPS reverse proxy separately. Workflow deploys
backend/AI only, not Flutter web hosting. No automatic DB rollback or deletion; failed
migration/health check fails workflow. New containers may already be running if a later
check fails; current symlink alone is not automatic rollback. Retain backups and inspect
failure before retry. Releases retained; manage disk usage deliberately.

Actual remote deployment NOT TESTED: no server credential supplied to this session.
Workflow CI may expose previously unexecuted database test failures; fix them rather
than bypassing gates. No remote push or deployment executed by coding agent.
