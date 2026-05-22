#!/usr/bin/env bash
# Gera carga na API para observar o HPA (requer metrics-server).
set -euo pipefail

DURATION="${DURATION:-120}"
CONCURRENCY="${CONCURRENCY:-20}"

kubectl port-forward -n desafio-api svc/desafio-api 8080:80 >/tmp/pf-load.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT
sleep 2

echo "Carga por ${DURATION}s (concorrencia ${CONCURRENCY}) — observe: kubectl get hpa -n desafio-api -w"
end=$((SECONDS + DURATION))
while [[ $SECONDS -lt $end ]]; do
  for _ in $(seq 1 "$CONCURRENCY"); do
    curl -fsS "http://127.0.0.1:8080/status" >/dev/null &
  done
  wait
done
echo "Carga finalizada."
