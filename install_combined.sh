#!/bin/sh
set -eu

REPO_RAW_BASE="https://raw.githubusercontent.com/techrelay/GL.iNet-CellularModels-SMSonBoot/main"
CONF="/etc/sms_on_boot_combined.conf"

PREFER=""
PHONE=""
TEXTBELT_KEY=""

usage() {
  cat <<'EOF'
SMS on Boot - Combined Installer

Interactive:
  install_combined.sh

Non-interactive:
  install_combined.sh --prefer textbelt|sendsms --phone +17192291657 [--textbelt-key KEY]

Examples:
  install_combined.sh --prefer textbelt --phone +17192291657 --textbelt-key textbelt
  install_combined.sh --prefer sendsms  --phone +17192291657
EOF
}

# Parse args (if any)
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --prefer) PREFER="${2:-}"; shift 2 ;;
    --phone) PHONE="${2:-}"; shift 2 ;;
    --textbelt-key) TEXTBELT_KEY="${2:-}"; shift 2 ;;
    --) shift; break ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl not found. Install requires curl access." >&2
  exit 1
fi

# If not enough args, go interactive
if [ -z "${PREFER:-}" ] || [ -z "${PHONE:-}" ]; then
  echo
  echo "SMS on Boot - Combined Installer"
  echo "--------------------------------"
  echo "Choose which provider to try FIRST:"
  echo "  1) Textbelt (HTTPS API; good for non-cellular models)"
  echo "  2) sendsms  (local SIM; cellular models only)"
  echo
  printf "Enter 1 or 2: "
  read choice

  if [ "$choice" = "2" ]; then
    PREFER="sendsms"
  else
    PREFER="textbelt"
  fi

  printf "Destination phone number (E.164, e.g. +17192291657): "
  read PHONE

  echo "Textbelt key (optional). Leave blank to skip Textbelt."
  echo "You can also use: textbelt (limited free tier)"
  printf "Textbelt key: "
  read TEXTBELT_KEY
fi

# Validate
if [ -z "${PHONE:-}" ]; then
  echo "ERROR: phone number is required." >&2
  exit 1
fi

if [ "$PREFER" != "textbelt" ] && [ "$PREFER" != "sendsms" ]; then
  echo "ERROR: --prefer must be textbelt or sendsms." >&2
  exit 1
fi

echo "[*] Downloading sms_on_boot_combined.sh..."
curl -fsSL "$REPO_RAW_BASE/sms_on_boot_combined.sh" -o /usr/bin/sms_on_boot_combined.sh
chmod +x /usr/bin/sms_on_boot_combined.sh

echo "[*] Writing config $CONF ..."
# Write config without sed, so special characters in the key never break anything.
umask 077
{
  echo "PHONE=\"$PHONE\""
  echo "PREFER=\"$PREFER\""
  echo "TEXTBELT_KEY=\"$TEXTBELT_KEY\""
} > "$CONF"

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
