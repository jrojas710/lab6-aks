#!/usr/bin/env bash
# Etapa 4: reinicia cada portal (y su BD) y comprueba que el contenido sigue.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
for portal in wordpress prestashop; do
  f=evidencias/05_reinicio_$portal.txt
  [ $portal = wordpress ] && { app=wordpress; bd=mysql; chk=verifica_wp; } || { app=prestashop; bd=mariadb; chk=verifica_ps; }
  {
    echo "===== ANTES del reinicio ($(date -Iseconds)) ====="
    kubectl -n $portal get pods -o wide; $chk
    echo; echo "===== kubectl rollout restart deploy/$bd deploy/$app ====="
    kubectl -n $portal rollout restart deploy/$bd deploy/$app
    kubectl -n $portal rollout status deploy/$bd --timeout=10m
    kubectl -n $portal rollout status deploy/$app --timeout=15m
    sleep 10
    echo; echo "===== DESPUÉS del reinicio ($(date -Iseconds)) — pods nuevos ====="
    kubectl -n $portal get pods -o wide; $chk
  } 2>&1 | tee "$f"
done
echo "Compara los nombres de pod y la edad (AGE): son pods nuevos y el contenido sigue."
