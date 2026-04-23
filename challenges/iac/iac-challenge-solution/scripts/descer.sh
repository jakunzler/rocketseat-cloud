#!/usr/bin/env bash
# Derruba a infra (terraform destroy) de um ambiente. Por predefinição pede confirmação.
# Carrega .env como em subir.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALID_ENVS="dev staging prod"
# shellcheck source=../lib/terraform-env.sh
# shellcheck disable=SC1091
source "${ROOT}/scripts/lib/terraform-env.sh"

usage() {
  echo "Uso: $0 {dev|staging|prod} [-y|--yes]" >&2
  echo "  -y / --yes: não pergunta confirmação (perigoso)." >&2
  exit 1
}

env="${1:-}"
yes_flag="${2:-}"
[[ -n "$env" ]] || usage
echo "$VALID_ENVS" | grep -qw -- "$env" || usage

if [[ "$env" == "-y" || "$env" == "--yes" ]]; then
  echo "O primeiro argumento deve ser o ambiente (dev, staging, prod)." >&2
  usage
fi

skip_confirm=0
if [[ "$yes_flag" == "-y" || "$yes_flag" == "--yes" ]]; then
  skip_confirm=1
fi

TARGET="${ROOT}/environments/${env}"
if [[ ! -d "$TARGET" ]]; then
  echo "Diretório inexistente: $TARGET" >&2
  exit 1
fi

if [[ "$skip_confirm" -eq 0 ]]; then
  read -r -p "Isto destrói a infra de '$env' no GCP (terraform destroy). Continuar? [s/N] " reply
  case "$reply" in
    [sS]|[sS][iI][mM]|[yY]|[yY][eE][sS]) ;;
    *) echo "Cancelado."; exit 0 ;;
  esac
fi

load_dotenv
build_tf_var_args

cd "$TARGET"
echo "==> Ambiente: $env (em $TARGET)"
if [[ ! -d .terraform ]]; then
  echo "==> terraform init (diretório .terraform em falta)"
  terraform init
fi
echo "==> terraform destroy -auto-approve"
terraform destroy -auto-approve "${tf_var_args[@]}"
echo "==> Ambiente $env derrubado."
