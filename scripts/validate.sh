#!/usr/bin/env bash
set -Eeuo pipefail
root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"
bash -n deploy.sh manage-user.sh scripts/*.sh
for profile in profiles/*.env; do
  docker compose --env-file .env.example --env-file "$profile" config --quiet
  echo "compose OK com $(basename "$profile")"
done
if [[ "${1:-}" == "--runtime" ]]; then
  docker compose ps --services --status running | grep -qx ftp
  container_id="$(docker compose ps -q ftp)"
  [[ "$(docker inspect --format '{{.State.Health.Status}}' "$container_id")" == healthy ]]
  docker compose exec -T ftp pure-pw show "${FTP_USER:-transfer}" -f /auth/pureftpd.passwd >/dev/null
fi
echo "Validacao FTP concluida."
