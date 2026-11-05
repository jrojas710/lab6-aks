#!/usr/bin/env bash
# Etapa 3 (asistentes): instala WordPress, crea la página de prueba y el producto de prueba.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
WPA=$(kubectl -n wordpress get secret wp-db -o jsonpath='{.data.admin-password}' | base64 -d)
PSA=$(kubectl -n prestashop get secret ps-db -o jsonpath='{.data.admin-password}' | base64 -d)

wp core is-installed 2>/dev/null || wp core install --url="http://$WP_IP" --title="Portal WordPress - Lab 6" \
  --admin_user=admin --admin_password="$WPA" --admin_email=admin@lab6.local --skip-email
[ -n "$(wp post list --post_type=page --name=pagina-prueba-lab6 --format=ids)" ] || \
  wp post create --post_type=page --post_status=publish --post_title="Pagina de prueba Lab 6" \
    --post_name=pagina-prueba-lab6 --post_content="Página creada el $(date '+%Y-%m-%d %H:%M') para la prueba de persistencia del Lab 6."

kubectl -n prestashop exec -i "$(PS_POD)" -- sh -c 'cd /var/www/html && php' < scripts/crear_producto.php

{ echo "== Contenido de prueba creado $(date -Iseconds) =="
  echo; echo "### WordPress (http://$WP_IP, admin: http://$WP_IP/wp-admin  usuario admin)"; verifica_wp
  echo; echo "### PrestaShop (http://$PS_IP, admin: http://$PS_IP/admin-lab6  usuario admin@lab6.local)"; verifica_ps
} | tee evidencias/04_contenido.txt
echo
echo "Claves de admin (NO las subas al repo): WordPress=$WPA  PrestaShop=$PSA"
