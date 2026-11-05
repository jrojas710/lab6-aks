#!/usr/bin/env bash
# Apagado: borra TODO lo creado (clúster, discos, IPs públicas, Grafana). Irreversible.
set -euo pipefail
cd "$(dirname "$0")/.."; source .lab6.env
read -rp "Esto elimina el grupo $RG y todo su contenido. Escribe SI para continuar: " ok
[ "$ok" = "SI" ] || exit 1
if [ "$MODO" = "azd" ]; then (cd infra-azd && azd down --force --purge)
else az group delete -n "$RG" --yes; fi
date -Iseconds | sed 's/^/Entorno eliminado: /' | tee evidencias/07_apagado.txt
az group list --query "[].name" -o tsv | tee -a evidencias/07_apagado.txt
