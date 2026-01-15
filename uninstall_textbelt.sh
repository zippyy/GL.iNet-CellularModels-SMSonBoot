#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

if [ -x /etc/init.d/sms_on_boot_textbelt ]; then
  /etc/init.d/sms_on_boot_textbelt disable >/dev/null 2>&1 || true
fi

rm -f /etc/init.d/sms_on_boot_textbelt
rm -f /usr/bin/sms_on_boot_textbelt.sh
rm -f /etc/sms_on_boot_textbelt.last

echo "[OK] Uninstalled Textbelt version."
