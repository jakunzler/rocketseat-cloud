#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Namespaces"
kubectl apply -f "$ROOT/k8s/00-namespaces.yaml"

echo "==> Banco (StorageClass, PV, PVC, Secret, Deployment, Service)"
kubectl apply -f "$ROOT/k8s/db/storageclass.yaml"
kubectl apply -f "$ROOT/k8s/db/pv.yaml"
kubectl apply -f "$ROOT/k8s/db/secret.yaml"
kubectl apply -f "$ROOT/k8s/db/pvc.yaml"
kubectl apply -f "$ROOT/k8s/db/deployment.yaml"
kubectl apply -f "$ROOT/k8s/db/service.yaml"

echo "Aguardando MySQL..."
kubectl rollout status deployment/mysql -n desafio-db --timeout=300s

echo "==> API (ConfigMap, Secret, Deployment, Services, HPA)"
kubectl apply -f "$ROOT/k8s/api/configmap.yaml"
kubectl apply -f "$ROOT/k8s/api/secret.yaml"
kubectl apply -f "$ROOT/k8s/api/deployment.yaml"
kubectl apply -f "$ROOT/k8s/api/service.yaml"
kubectl apply -f "$ROOT/k8s/api/hpa.yaml"

if [[ "${APPLY_NODEPORT:-}" == "1" ]]; then
  kubectl apply -f "$ROOT/k8s/api/service-nodeport.yaml"
fi

echo "Aguardando API..."
kubectl rollout status deployment/desafio-api -n desafio-api --timeout=300s

echo "==> Recursos"
kubectl get all -n desafio-db
kubectl get all -n desafio-api
kubectl get hpa -n desafio-api
kubectl get pvc -n desafio-db
