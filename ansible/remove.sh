#!/usr/bin/env bash
set -e

echo "[*] Removing /opt/fing"
sudo rm -rf /opt/fing

echo "[*] Removing /usr/local/bin/fing symlink if present"
sudo rm -f /usr/local/bin/fing

echo "[*] Removing /usr/lib/fing directory if present"
sudo rm -rf /usr/lib/fing

echo "[*] Removing library loader config"
sudo rm -f /etc/ld.so.conf.d/fing.conf

echo "[*] Updating linker cache"
sudo ldconfig

echo "[+] Fing uninstalled and related paths cleaned up."
