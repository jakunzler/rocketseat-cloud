#!/usr/bin/env bash
# Testa integracao API <-> MySQL via port-forward ou NodePort.
set -euo pipefail

MODE="${1:-port-forward}"
BASE_URL=""

if [[ "$MODE" == "nodeport" ]]; then
  NODE_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"
  BASE_URL="http://${NODE_IP}:30080"
else
  kubectl port-forward -n desafio-api svc/desafio-api 8080:80 >/tmp/pf-api.log 2>&1 &
  PF_PID=$!
  trap 'kill $PF_PID 2>/dev/null || true' EXIT
  sleep 2
  BASE_URL="http://127.0.0.1:8080"
fi

echo "==> GET $BASE_URL/status"
curl -fsS "$BASE_URL/status" | tee /tmp/status.json
echo

echo "==> POST $BASE_URL/dados"
curl -fsS -X POST "$BASE_URL/dados" \
  -H 'Content-Type: application/json' \
  -d '{"titulo":"teste-k8s","valor":42}' | tee /tmp/post.json
echo

echo "==> GET $BASE_URL/dados"
curl -fsS "$BASE_URL/dados" | tee /tmp/list.json
echo

echo "Testes concluidos."
