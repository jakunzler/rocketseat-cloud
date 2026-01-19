#!/usr/bin/env bash
set -euo pipefail

GNB_CTN="ueransim-gnb-rocket"

N2_PFX="10.20.0."
N3_PFX="10.30.0."

echo "[INFO] Aguardando interfaces subirem no container..."
# Aguarda o container estar "up"
for i in {1..30}; do
  if docker ps --format '{{.Names}}' | grep -q "^${GNB_CTN}$"; then
    break
  fi
  sleep 1
done

# Aguarda IPs aparecerem
for i in {1..30}; do
  IPS="$(docker exec "$GNB_CTN" sh -lc "ip -o -4 addr show | awk '{print \$2, \$4}'" || true)"
  echo "$IPS" | grep -q "$N2_PFX" && echo "$IPS" | grep -q "$N3_PFX" && break
  sleep 1
done

N2_IFACE="$(docker exec "$GNB_CTN" sh -lc "ip -o -4 addr show | awk -v pfx='$N2_PFX' '\$4 ~ \"^\"pfx {print \$2; exit}'")"
N3_IFACE="$(docker exec "$GNB_CTN" sh -lc "ip -o -4 addr show | awk -v pfx='$N3_PFX' '\$4 ~ \"^\"pfx {print \$2; exit}'")"

if [ -z "$N2_IFACE" ] || [ -z "$N3_IFACE" ]; then
  echo "[FATAL] Nao foi possivel identificar N2/N3 ifaces."
  docker exec "$GNB_CTN" sh -lc "ip -br a" || true
  exit 1
fi

echo "[INFO] Detectado:"
echo "  N2_IFACE=$N2_IFACE"
echo "  N3_IFACE=$N3_IFACE"

# Atualiza variáveis de ambiente do serviço via override (sem editar o compose principal)
mkdir -p ./overrides

cat > ./overrides/ueransim-ifaces.override.yml <<EOF
services:
  ueransim-gnb:
    environment:
      - N2_IFACE=${N3_IFACE}
      - N3_IFACE=${N2_IFACE}
      - RADIO_IFACE=${N2_IFACE}
EOF

echo "[INFO] Recriando apenas o gNB com override..."
docker compose -f docker-compose.yml -f ./overrides/ueransim-ifaces.override.yml up -d --force-recreate ueransim-gnb

echo "[OK] gNB recriado com N2/N3 corretos."
