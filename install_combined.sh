#!/bin/sh
set -eu

PHONE="${1:-}"
PREFER="${2:-}"
TEXTBELT_KEY="${3:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

# ---- Interactive fallback ----
if [ -z "$PHONE" ] || [ -z "$PREFER" ]; then
  echo
  echo "SMS on Boot - Combined Installer"
  echo "--------------------------------"
  echo "Choose which provider to try FIRST:"
  echo "  1) Textbelt (HTTPS API)"
  echo "  2) sendsms  (local SIM)"
  echo
  printf "Enter 1 or 2: "
  read choice

  PREFER="textbelt"
  [ "$choice" = "2" ] && PREFER="sendsms"

  printf "Destination phone number (E.164, e.g. +17192291657): "
  read PHONE

  if [ "$PREFER" = "textbelt" ]; then
    printf "Textbelt key (or 'textbelt' for free tier): "
    read TEXTBELT_KEY
  fi
fi

# ---- Validation ----
if [ -z "$PHONE" ]; then
  echo "ERROR: phone number required" >&2
  exit 1
fi

case "$PREFER" in
  textbelt|sendsms) ;;
  *)
    echo "ERROR: prefer must be 'textbelt' or 'sendsms'" >&2
    exit 1
    ;;
esac

if [ "$PREFER" = "textbelt" ] && [ -z "$TEXTBELT_KEY" ]; then
  echo "ERROR: Textbelt key required when prefer=textbelt" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl not found." >&2
  exit 1
fi

echo "[*] Downloading sms_on_boot_combined.sh..."
curl -fsSL \
  https://raw.githubusercontent.com/zippyy/GL.iNet-CellularModels-SMSonBoot/main/sms_on_boot_combined.sh \
  -o /usr/bin/sms_on_boot_combined.sh

chmod +x /usr/bin/sms_on_boot_combined.sh

# ---- Apply config ----
sed -i "s|^PHONE=\".*\"|PHONE=\"$PHONE\"|g" /usr/bin/sms_on_boot_combined.sh
sed -i "s|^PREFER=\".*\"|PREFER=\"$PREFER\"|g" /usr/bin/sms_on_boot_combined.sh
sed -i "s|^TEXTBELT_KEY=\".*\"|TEXTBELT_KEY=\"$TEXTBELT_KEY\"|g" /usr/bin/sms_on_boot_combined.sh

echo "[*] Creating init.d service..."
cat > /etc/init.d/sms_on_boot_combined <<'EOF'
#!/bin/sh /etc/rc.common
START=99
start() {
  /usr/bin/sms_on_boot_combined.sh &
}
EOF

chmod +x /etc/init.d/sms_on_boot_combined
/etc/init.d/sms_on_boot_combined enable

echo "[OK] Installed Combined version."
echo "To test immediately (no reboot required):"
echo "  rm -f /etc/sms_on_boot_combined.last"
echo "  /usr/bin/sms_on_boot_combined.sh"
echo "  cat /tmp/sms_on_boot_combined.log"
