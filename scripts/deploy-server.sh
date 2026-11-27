#!/usr/bin/env bash
set -euo pipefail
root=${1:?Deployment root required}
revision=${2:?Commit required}
[[ "$root" =~ ^/[a-zA-Z0-9_/-]+$ && "$root" != / && "$root" != *..* ]]
[[ "$revision" =~ ^[a-f0-9]{40}$ ]]
release="$root/releases/$revision"
envfile="$root/shared/backend.env"
if [[ ! -s "$envfile" ]]; then
  echo "Missing $envfile. Create it once using backend/.env.example; no secrets are generated automatically."
  exit 1
fi
chmod 600 "$envfile"
docker compose version
docker info > /dev/null
cd "$release/backend"
ln -sfn "$envfile" .env
# Stable project name preserves network/volume identity across releases.
compose=(docker compose --project-name vita --env-file "$envfile" -f "$release/backend/docker-compose.yml")
"${compose[@]}" config --quiet
"${compose[@]}" build
"${compose[@]}" up -d --wait --wait-timeout 120 db
# Run migrations explicitly on every release; no rollback/down or volume deletion.
"${compose[@]}" run --rm --no-deps migrate
"${compose[@]}" up -d --no-deps --wait --wait-timeout 180 api ai-service
"${compose[@]}" up -d --no-deps worker
sleep 5
worker=$("${compose[@]}" ps -q worker)
test -n "$worker"
test "$(docker inspect -f '{{.State.Running}}' "$worker")" = true
curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8080/health/ready
ln -sfn "$release" "$root/current"
echo "Deployment successful: $revision"
