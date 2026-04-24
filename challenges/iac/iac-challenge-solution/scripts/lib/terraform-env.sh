# shellcheck shell=bash
# Carrega arquivos .env e monta argumentos -var (precedência máxima no Terraform) a partir
# de TF_VAR_<nome> para não serem sobrescritos por terraform.tfvars local.

# Uso: após definir ROOT e TARGET; source este arquivo; load_dotenv; build_tf_var_args; terraform apply "${tf_var_args[@]}"

load_dotenv() {
  local f
  for f in "${ROOT}/.env" "${TARGET}/.env"; do
    if [[ -f "$f" ]]; then
      set -a
      # shellcheck source=/dev/null
      . "$f"
      set +a
      echo "==> Carregou variáveis de: $f" >&2
    fi
  done
}

# Nomes alinhados com variables.tf (escalares). Não incluímos "environment" — vem do diretório.
build_tf_var_args() {
  tf_var_args=()
  local n e
  for n in project_id region zone subnetwork_cidr proxy_subnetwork_cidr machine_type min_replicas \
    max_replicas boot_disk_size_gb ssh_ingress_cidr app_secret_id; do
    e="TF_VAR_${n}"
    if [[ -n "${!e:-}" ]]; then
      tf_var_args+=(-var="${n}=${!e}")
    fi
  done
  # map(string); valor JSON (ex.: {"project":"iac-challenge"}) no .env com aspas adequadas
  if [[ -n "${TF_VAR_common_labels:-}" ]]; then
    tf_var_args+=(-var="common_labels=${TF_VAR_common_labels}")
  fi
}
