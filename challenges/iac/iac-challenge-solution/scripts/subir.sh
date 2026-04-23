#!/usr/bin/env bash
# Sobe a infra (terraform init + apply) de um ambiente: dev, staging ou prod.
# Lê $ROOT/.env e environments/<env>/.env (não versionados) e aplica -var a partir
# de TF_VAR_* (precedência acima de terraform.tfvars). Ver .env.example na raiz.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALID_ENVS="dev staging prod"
# shellcheck source=../lib/terraform-env.sh
# shellcheck disable=SC1091
source "${ROOT}/scripts/lib/terraform-env.sh"

usage() {
  echo "Uso: $0 {dev|staging|prod}" >&2
  echo "  Copie .env.example para .env (raiz) e defina TF_VAR_project_id, ou crie" >&2
  echo "  environments/<env>/terraform.tfvars a partir de terraform.tfvars.example." >&2
  exit 1
}

env="${1:-}"
[[ -n "$env" ]] || usage
echo "$VALID_ENVS" | grep -qw -- "$env" || usage

TARGET="${ROOT}/environments/${env}"
if [[ ! -d "$TARGET" ]]; then
  echo "Diretório inexistente: $TARGET" >&2
  exit 1
fi

load_dotenv
build_tf_var_args

cd "$TARGET"
echo "==> Ambiente: $env (em $TARGET)"
echo "==> terraform init"
terraform init
echo "==> terraform apply -auto-approve"
terraform apply -auto-approve "${tf_var_args[@]}"
echo "==> Concluído. Outputs:"
terraform output -no-color 2>/dev/null || true
