#!/usr/bin/env bash
# Etapa 1: AKS + Grafana.
#   MODO=azd (por defecto): template sabbour/aks-app-template con azd.
#   MODO=az : plan B con Azure CLI (si el template falla o excede la cuota de estudiante).
set -euo pipefail
cd "$(dirname "$0")/.."
MODO="${MODO:-azd}"
LOC="${LOC:-eastus2}"

az account show >/dev/null 2>&1 || az login --use-device-code
for p in Microsoft.ContainerService Microsoft.Dashboard Microsoft.Monitor Microsoft.AlertsManagement Microsoft.Insights Microsoft.OperationalInsights; do
  az provider register -n "$p" --wait --only-show-errors
done

if [ "$MODO" = "azd" ]; then
  azd auth login --check-status >/dev/null 2>&1 || azd auth login --use-device-code
  mkdir -p infra-azd && cd infra-azd
  [ -f azure.yaml ] || azd init -t https://github.com/sabbour/aks-app-template -e lab6
  azd env set AZURE_LOCATION "$LOC"
  azd provision
  cd ..
  RG=$(az aks list --query "[0].resourceGroup" -o tsv)
  AKS=$(az aks list --query "[0].name" -o tsv)
  GRAF=$(az grafana list --query "[?resourceGroup=='$RG'].name | [0]" -o tsv 2>/dev/null || true)
  if [ -z "$GRAF" ]; then GRAF=$(az grafana list --query "[0].name" -o tsv); fi
else
  RG=rg-lab6; AKS=aks-lab6; GRAF="graf-lab6-$(openssl rand -hex 3)"
  az group create -n "$RG" -l "$LOC" -o none
  az aks create -g "$RG" -n "$AKS" -l "$LOC" --tier free \
    --node-count 2 --node-vm-size Standard_B2s --generate-ssh-keys -o none
  az grafana create -g "$RG" -n "$GRAF" -l "$LOC" -o none
fi

GRG=$(az grafana list --query "[?name=='$GRAF'].resourceGroup | [0]" -o tsv)
GID=$(az grafana show -g "$GRG" -n "$GRAF" --query id -o tsv)

# Métricas del clúster hacia Grafana (Managed Prometheus). Si el template ya lo hizo, no cambia nada.
if [ "$(az aks show -g "$RG" -n "$AKS" --query 'azureMonitorProfile.metrics.enabled' -o tsv)" != "true" ]; then
  AMW_ID=$(az monitor account create -g "$RG" -n amw-lab6 -l "$(az aks show -g "$RG" -n "$AKS" --query location -o tsv)" --query id -o tsv)
  az aks update -g "$RG" -n "$AKS" --enable-azure-monitor-metrics \
    --azure-monitor-workspace-resource-id "$AMW_ID" --grafana-resource-id "$GID" -o none
fi
az role assignment create --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --role "Grafana Admin" --scope "$GID" -o none 2>/dev/null || true

az aks get-credentials -g "$RG" -n "$AKS" --overwrite-existing
cat > .lab6.env <<EOV
MODO=$MODO
RG=$RG
AKS=$AKS
GRAF=$GRAF
GRG=$GRG
EOV

{
  echo "Fecha: $(date -Iseconds)"
  echo "Modo de aprovisionamiento: $MODO"
  echo "Grupo de recursos: $RG   Clúster: $AKS"
  echo "Región: $(az aks show -g "$RG" -n "$AKS" --query location -o tsv)"
  echo "Versión de Kubernetes: $(az aks show -g "$RG" -n "$AKS" --query kubernetesVersion -o tsv)"
  echo "Tamaño de nodo: $(az aks show -g "$RG" -n "$AKS" --query 'agentPoolProfiles[0].vmSize' -o tsv) x $(az aks show -g "$RG" -n "$AKS" --query 'agentPoolProfiles[0].count' -o tsv)"
  echo "Grafana: $(az grafana show -g "$GRG" -n "$GRAF" --query properties.endpoint -o tsv)"
  echo; kubectl get nodes -o wide
} | tee evidencias/01_cluster.txt
