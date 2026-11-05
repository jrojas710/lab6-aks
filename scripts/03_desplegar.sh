#!/usr/bin/env bash
# Etapa 2b y 3: las dos BD y los dos portales.
set -euo pipefail
cd "$(dirname "$0")/.."
ip_de() {  # espera la IP pública de un Service LoadBalancer
  local ip=""
  until [ -n "$ip" ]; do
    ip=$(kubectl -n "$1" get svc "$2" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    [ -n "$ip" ] || { echo "esperando IP pública de $1/$2..." >&2; sleep 10; }
  done
  echo "$ip"
}

kubectl apply -f k8s/wordpress/mysql.yaml -f k8s/prestashop/mariadb.yaml
kubectl -n wordpress rollout status deploy/mysql --timeout=10m
kubectl -n prestashop rollout status deploy/mariadb --timeout=10m
{ echo "== Bases de datos =="; kubectl get pods,pvc,svc -n wordpress -l 'app in (mysql)' ; kubectl get pvc -n wordpress
  kubectl get pods,svc -n prestashop -l 'app in (mariadb)'; kubectl get pvc -n prestashop; } | tee evidencias/02_bases_de_datos.txt

# WordPress
kubectl apply -f k8s/wordpress/wordpress.yaml
# PrestaShop: primero el Service para conocer la IP y ponerla en PS_DOMAIN
kubectl apply -f k8s/prestashop/prestashop-svc.yaml
PS_IP=$(ip_de prestashop prestashop)
kubectl -n prestashop create configmap ps-config --from-literal=PS_DOMAIN="$PS_IP" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s/prestashop/prestashop.yaml
WP_IP=$(ip_de wordpress wordpress)

kubectl -n wordpress rollout status deploy/wordpress --timeout=10m
echo "Instalando PrestaShop (tarda 5-10 min la primera vez)..."
kubectl -n prestashop rollout status deploy/prestashop --timeout=25m

printf "WP_IP=%s\nPS_IP=%s\n" "$WP_IP" "$PS_IP" >> .lab6.env
{ echo "WordPress:  http://$WP_IP"
  echo "PrestaShop: http://$PS_IP   (admin: http://$PS_IP/admin-lab6)"
  echo; kubectl get deploy,pods,svc,pvc -n wordpress; echo; kubectl get deploy,pods,svc,pvc -n prestashop
  echo; echo "Las BD son ClusterIP (sin IP externa); solo los portales son LoadBalancer."
} | tee evidencias/03_portales.txt
