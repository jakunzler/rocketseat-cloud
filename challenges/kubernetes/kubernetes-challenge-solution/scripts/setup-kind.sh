#!/usr/bin/env bash
# Cria cluster Kind e instala metrics-server (necessario para HPA).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${KIND_CLUSTER_NAME:-desafio-k8s}"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster '$CLUSTER_NAME' ja existe. Use: kubectl cluster-info --context kind-$CLUSTER_NAME"
  exit 0
fi

kind create cluster --name "$CLUSTER_NAME" --config "$ROOT/cluster/kind-config.yaml"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
kubectl apply -f "$ROOT/cluster/metrics-server.yaml"
echo "Aguardando metrics-server..."
kubectl rollout status deployment/metrics-server -n kube-system --timeout=120s
echo "Cluster pronto."
