#!/usr/bin/env bash
# Corre las etapas 1 a 6 en orden. El apagado (07) se corre aparte, al final.
set -euo pipefail
cd "$(dirname "$0")"
./00_herramientas.sh
./01_infra.sh
./02_secrets.sh
./03_desplegar.sh
./04_contenido.sh
./05_reinicio.sh
./06_grafana.sh
echo; echo "LISTO. Toma las capturas (ver README) y luego corre scripts/07_apagar.sh"
