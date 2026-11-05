#!/usr/bin/env bash
# Etapa 2a: namespaces y Secrets con contraseñas aleatorias (nunca en el YAML del repo).
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl apply -f k8s/namespaces.yaml
for par in wordpress:wp-db prestashop:ps-db; do
  ns=${par%%:*}; s=${par##*:}
  kubectl -n "$ns" get secret "$s" >/dev/null 2>&1 && { echo "$ns/$s ya existe"; continue; }
  kubectl -n "$ns" create secret generic "$s" \
    --from-literal=root-password="$(openssl rand -hex 16)" \
    --from-literal=password="$(openssl rand -hex 16)" \
    --from-literal=admin-password="Lab6-$(openssl rand -hex 6)"
done
