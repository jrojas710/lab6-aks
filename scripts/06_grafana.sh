#!/usr/bin/env bash
# Importa el dashboard que separa los pods de los dos portales y muestra el enlace.
set -euo pipefail
cd "$(dirname "$0")/.."; source .lab6.env
az grafana dashboard import -g "$GRG" -n "$GRAF" --definition grafana/dashboard-lab6.json --overwrite true -o none
URL=$(az grafana show -g "$GRG" -n "$GRAF" --query properties.endpoint -o tsv)
echo "Grafana: $URL/d/lab6-portales  (inicia sesión con tu cuenta de Azure)" | tee evidencias/06_grafana.txt
echo "Si los paneles salen vacíos, espera 5-10 min: Managed Prometheus tarda en recibir las primeras métricas." | tee -a evidencias/06_grafana.txt
