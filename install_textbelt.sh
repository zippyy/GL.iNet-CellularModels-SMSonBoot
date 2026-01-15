#!/bin/sh
set -eu

PHONE="${1:-}"
KEY="${2:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

if [ -z "$PHONE" ] || [ -z "$KEY" ]; then
  echo "Usage: install_textbelt.sh <PHONE> <TEXTBELT_KEY>" >&2
  echo "Example: install_textbelt.sh +17192291657 your_key_here" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl not found." >&2
  exit 1
fi

echo "[*] Downloading sms_on_boot_textbelt.sh..."
curl -fsSL \
  https://raw.githubusercontent.com/zippyy/GL.iNet-CellularModels-SMSonBoot/main/sms_on_boot_textbelt.sh \
  -o /usr/bin/sms_on_boot_textbelt.sh

chmod +x /usr/bin/sms_on_boot_textbelt.sh

# Set PHONE + KEY inside the script (simple + obvious)
sed -i "s|^PHONE=\".*\"|PHONE=\"$PHONE\"|g" /usr/bin/sms_on_boot_textbelt.sh
sed -i "s|^TEXTBELT_KEY=\".*\"|TEXTBELT_KEY=\"$KEY\"|g" /usr/bin/sms_on_boot_textbelt.sh

echo "[*] Creating init.d service..."
cat > /etc/init.d/sms_on_boot_textbelt <<'EOF'
#!/bin/sh /etc/rc.common
START=99
start() {
  /usr/bin/sms_on_boot_textbelt.sh &
}
EOF

chmod +x /etc/init.d/sms_on_boot_textbelt
/etc/init.d/sms_on_boot_textbelt enable

echo "[OK] Installed Textbelt version."
echo "To test immediately (no reboot required):"
echo "  rm -f /etc/sms_on_boot_textbelt.last"
echo "  /usr/bin/sms_on_boot_textbelt.sh"
echo "  cat /tmp/sms_on_boot_textbelt.log"
