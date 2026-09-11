#!/usr/bin/env bash
set -Eeuo pipefail
root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$root_dir"
action="${1:-}"
user="${2:-}"
case "$action" in
  list|del)
    docker compose exec -T ftp allsafe-ftp-user "$action" "$user"
    ;;
  add|passwd)
    read -r -s -p "Senha para $user: " password
    echo
    printf '%s\n' "$password" | docker compose exec -T ftp allsafe-ftp-user "$action" "$user"
    unset password
    ;;
  *) echo "Uso: $0 add|passwd|del|list [usuario]" >&2; exit 2 ;;
esac

