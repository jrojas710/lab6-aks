#!/usr/bin/env bash
# Instala Azure CLI, azd y kubectl si faltan (pensado para GitHub Codespaces / Ubuntu).
set -euo pipefail
command -v az >/dev/null || curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
command -v azd >/dev/null || curl -fsSL https://aka.ms/install-azd.sh | bash
command -v kubectl >/dev/null || sudo az aks install-cli
az extension add -n amg -y --only-show-errors
az version --query '"azure-cli"' -o tsv; azd version; kubectl version --client | head -1
