#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

echo "[*] Disabling service..."
if [ -x /etc/init.d/sms_on_boot_combined ]; then
  /etc/init.d/sms_on_boot_combined disable >/dev/null 2>&1 || true
fi

echo "[*] Removing files..."
rm -f /etc/init.d/sms_on_boot_combined
rm -f /usr/bin/sms_on_boot_combined.sh
rm -f /etc/sms_on_boot_combined.last
rm -f /tmp/sms_on_boot_combined.log

echo "[OK] Combined SMS-on-boot uninstalled."
