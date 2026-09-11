#!/usr/bin/env bash
set -Eeuo pipefail

usage() { echo "Uso: $0 add|passwd|del|list [usuario]" >&2; exit 2; }
action="${1:-}"
user="${2:-}"
passwd_file=/auth/pureftpd.passwd

case "$action" in
  list)
    pure-pw list -f "$passwd_file"
    ;;
  add|passwd)
    [[ "$user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || usage
    IFS= read -r password
    [[ ${#password} -ge 12 ]] || { echo "Senha deve ter pelo menos 12 caracteres" >&2; exit 1; }
    if [[ "$action" == add ]]; then
      install -d -o ftpdata -g ftpdata -m 0750 "/data/$user"
      printf '%s\n%s\n' "$password" "$password" | pure-pw useradd "$user" \
        -f "$passwd_file" -u ftpdata -g ftpdata -d "/data/$user"
    else
      printf '%s\n%s\n' "$password" "$password" | pure-pw passwd "$user" -f "$passwd_file"
    fi
    pure-pw mkdb /auth/pureftpd.pdb -f "$passwd_file"
    chmod 0600 "$passwd_file" /auth/pureftpd.pdb
    ;;
  del)
    [[ "$user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || usage
    pure-pw userdel "$user" -f "$passwd_file"
    pure-pw mkdb /auth/pureftpd.pdb -f "$passwd_file"
    echo "Usuario removido; os dados em /data/$user foram preservados."
    ;;
  *) usage ;;
esac

