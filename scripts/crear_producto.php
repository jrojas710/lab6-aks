<?php
// Crea el producto de prueba del Lab 6 con las clases de PrestaShop (se ejecuta dentro del pod).
require 'config/config.inc.php';
$existe = Db::getInstance()->getValue("SELECT id_product FROM " . _DB_PREFIX_ . "product_lang WHERE name = 'Producto de prueba Lab 6'");
if ($existe) { echo "producto ya existe id=$existe\n"; exit; }
$home = (int) Configuration::get('PS_HOME_CATEGORY');
$p = new Product();
foreach (Language::getLanguages(false) as $l) {
    $p->name[$l['id_lang']] = 'Producto de prueba Lab 6';
    $p->link_rewrite[$l['id_lang']] = 'producto-prueba-lab-6';
    $p->description_short[$l['id_lang']] = 'Producto creado para la prueba de persistencia del Lab 6.';
}
$p->price = 25000;
$p->id_category_default = $home;
$p->active = 1;
$p->visibility = 'both';
$p->add();
$p->addToCategories([$home]);
StockAvailable::setQuantity($p->id, 0, 10);
Search::indexation(false, $p->id);
echo "producto creado id={$p->id}\n";
