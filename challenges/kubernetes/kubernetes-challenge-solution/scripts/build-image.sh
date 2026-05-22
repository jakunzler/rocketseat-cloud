#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-desafio-api:local}"
CLUSTER_NAME="${KIND_CLUSTER_NAME:-desafio-k8s}"

docker build -t "$IMAGE" "$ROOT/app"

if command -v kind >/dev/null 2>&1 && kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"
  echo "Imagem carregada no Kind ($CLUSTER_NAME)."
else
  echo "Imagem local: $IMAGE (carregue no cluster com kind load ou push para registry)."
fi
