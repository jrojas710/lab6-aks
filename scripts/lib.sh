# Funciones compartidas por 04 y 05.
cd "$(dirname "$0")/.."
source .lab6.env
WP_POD() { kubectl -n wordpress get pod -l app=wordpress -o jsonpath='{.items[0].metadata.name}'; }
PS_POD() { kubectl -n prestashop get pod -l app=prestashop -o jsonpath='{.items[0].metadata.name}'; }
wp() {  # wp-cli dentro del pod de WordPress (se descarga a /tmp si no está)
  kubectl -n wordpress exec "$(WP_POD)" -- sh -c '[ -f /tmp/wp ] || curl -sSLo /tmp/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar' >/dev/null
  kubectl -n wordpress exec "$(WP_POD)" -- php /tmp/wp --allow-root --path=/var/www/html "$@"
}
verifica_wp() {
  echo "-- Página en la BD de WordPress:"
  wp post list --post_type=page --name=pagina-prueba-lab6 --fields=ID,post_title,post_date,post_status
  echo "-- HTTP http://$WP_IP/?pagename=pagina-prueba-lab6 :"
  curl -s "http://$WP_IP/?pagename=pagina-prueba-lab6" | grep -o '<title>[^<]*</title>' || echo "(no se encontró)"
}
verifica_ps() {
  echo "-- Producto en la BD de PrestaShop:"
  kubectl -n prestashop exec deploy/mariadb -- sh -c \
    'mariadb -uprestashop -p"$MARIADB_PASSWORD" prestashop -e "SELECT p.id_product, pl.name, p.price, p.date_add FROM ps_product p JOIN ps_product_lang pl USING(id_product) WHERE pl.name LIKE \"%Lab 6%\""'
  echo "-- HTTP http://$PS_IP (buscador):"
  curl -s "http://$PS_IP/index.php?controller=search&s=Lab+6" | grep -o 'Producto de prueba Lab 6' | head -1 || echo "(no se encontró)"
}
