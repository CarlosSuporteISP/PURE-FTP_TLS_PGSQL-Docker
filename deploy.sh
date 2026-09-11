#!/usr/bin/env bash
set -Eeuo pipefail
root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$root_dir"

size=small
check_only=false
usage() { echo "Uso: $0 [--size small|medium|large] [--check-only]"; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --size) size="${2:?Informe o perfil}"; shift 2 ;;
    --check-only) check_only=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção inválida: $1" >&2; usage >&2; exit 64 ;;
  esac
done

profile_file="profiles/${size}.env"
[[ -f "$profile_file" ]] || { echo "ERRO: perfil inexistente: $size" >&2; usage >&2; exit 64; }
[[ -f .env ]] || { cp .env.example .env; chmod 0600 .env; echo "Edite $root_dir/.env e execute novamente."; exit 1; }

# Senha do usuário inicial: gera uma forte na primeira execução se o arquivo
# estiver vazio/ausente. Para usar uma senha específica, grave-a antes de rodar.
secret_file=".secrets/ftp_password.txt"
umask 077
mkdir -p .secrets
if [[ ! -s "$secret_file" ]]; then
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 36 > "$secret_file"
  else
    tr -dc 'A-Za-z0-9_-' < /dev/urandom | head -c 48 > "$secret_file"
    echo >> "$secret_file"
  fi
  echo "Gerada uma senha forte em $secret_file (0600). Guarde-a para o cliente FTP."
fi
chmod 0600 "$secret_file"

compose() { docker compose --env-file .env --env-file "$profile_file" "$@"; }

compose config --quiet
if [[ "$check_only" == true ]]; then
  echo "OK: perfil '$size' e compose validados; nada foi alterado."
  exit 0
fi
compose up -d --build
compose ps
