#!/bin/sh
set -eu

PHONE="${1:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

if ! command -v sendsms >/dev/null 2>&1; then
  echo "ERROR: sendsms not found. GL.iNet firmware required." >&2
  exit 1
fi

echo "[*] Downloading sms_on_boot.sh..."
curl -fsSL \
  https://raw.githubusercontent.com/zippyy/GL.iNet-CellularModels-SMSonBoot/main/sms_on_boot.sh \
  -o /usr/bin/sms_on_boot.sh

chmod +x /usr/bin/sms_on_boot.sh

if [ -n "$PHONE" ]; then
  sed -i "s|^PHONE=\".*\"|PHONE=\"$PHONE\"|g" /usr/bin/sms_on_boot.sh
  echo "[*] Set PHONE to: $PHONE"
else
  echo "[!] No phone provided. Edit /usr/bin/sms_on_boot.sh later."
fi

echo "[*] Creating init.d service..."
cat > /etc/init.d/sms_on_boot <<'EOF'
#!/bin/sh /etc/rc.common
START=99
start() {
  /usr/bin/sms_on_boot.sh &
}
EOF

chmod +x /etc/init.d/sms_on_boot
/etc/init.d/sms_on_boot enable

echo "[OK] Installed."
echo "To test immediately (no reboot required):"
echo "  rm -f /etc/sms_on_boot.last && /usr/bin/sms_on_boot.sh && cat /tmp/sms_on_boot.log"
