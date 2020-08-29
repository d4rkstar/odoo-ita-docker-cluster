#!/bin/bash -x

cd /tmp/extra

echo ""
echo "Cloning Most recente Repository:"
echo ""

for repo in $(grep -v '^#' ./extra-repositories-list.txt)
do
  git clone -b $1 --depth=1 $repo
done

echo ""
echo "Preparing Addons Folder"
echo ""

for module in $(grep -v '^#' ./extra-modules-list.txt)
do
  find . -maxdepth 2 -type d -name $module -exec sh -c 'cp -f -a {} /var/lib/odoo_addons/' ';'
done

echo ""
echo "Modules installed:"
echo ""
ls -1 /var/lib/odoo_addons/
echo ""

chown -R odoo /var/lib/odoo_addons

rm -rf /tmp/*
