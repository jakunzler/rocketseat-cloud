#!/usr/bin/env bash
# Verifica GET /health com retentativas (App Runner pode demorar a ficar RUNNING).
set -euo pipefail

BASE_URL="${1:-}"
if [[ -z "$BASE_URL" ]]; then
  echo "Uso: $0 <service_url_base>" >&2
  echo "Ex.: $0 https://abc.us-east-1.awsapprunner.com" >&2
  exit 1
fi

BASE_URL="${BASE_URL%/}"
URL="${BASE_URL}/health"
MAX_ATTEMPTS="${HEALTH_CHECK_ATTEMPTS:-30}"
SLEEP_SEC="${HEALTH_CHECK_SLEEP:-10}"

echo "==> Health check: $URL (ate ${MAX_ATTEMPTS} tentativas)"

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  if response=$(curl -fsS "$URL" 2>/dev/null); then
    echo "$response" | grep -q '"status"[[:space:]]*:[[:space:]]*"ok"' || {
      echo "Resposta inesperada: $response" >&2
      exit 1
    }
    echo "==> OK na tentativa $attempt"
    exit 0
  fi
  echo "Tentativa $attempt/$MAX_ATTEMPTS falhou; aguardando ${SLEEP_SEC}s..."
  sleep "$SLEEP_SEC"
done

echo "Health check falhou apos $MAX_ATTEMPTS tentativas." >&2
exit 1
