#!/bin/sh
LOG="/tmp/sms_on_boot_textbelt.log"
STATE="/etc/sms_on_boot_textbelt.last"
COOLDOWN=300   # seconds (5 min)

PHONE="+11234567890"        # change if needed
TEXTBELT_KEY="textbelt"     # set your key here

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

# Find active WAN interface (best-effort)
find_wan_iface() {
  dev="$(ip route 2>/dev/null | awk '/^default /{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
  if [ -n "$dev" ]; then
    case "$dev" in
      lo|br-lan|lan*|eth*|en*|wl*|wlan*|phy*|ap*|bat*|ifb*|docker*|veth*|tun*|wg*|tailscale* ) ;;
      *) echo "$dev"; return 0 ;;
    esac
  fi

  for dev in $(ls /sys/class/net 2>/dev/null); do
    case "$dev" in
      wan*|ppp*|wwan*|usb*|rmnet*|mhi*|cdc*|en*|eth* )
        ip -4 addr show dev "$dev" 2>/dev/null | grep -q "inet " && { echo "$dev"; return 0; }
        ;;
    esac
  done

  return 1
}

# Cooldown guard
now="$(date +%s)"
if [ -f "$STATE" ]; then
  last="$(cat "$STATE" 2>/dev/null | tr -dc '0-9')"
  if [ -n "$last" ] && [ $((now-last)) -lt "$COOLDOWN" ]; then
    log "Cooldown active ($((now-last))s < ${COOLDOWN}s), skipping."
    exit 0
  fi
fi

# Require curl
if ! command -v curl >/dev/null 2>&1; then
  log "ERROR: curl not found."
  exit 1
fi

# Require key
if [ -z "$TEXTBELT_KEY" ] || [ "$TEXTBELT_KEY" = "YOUR_KEY_HERE" ]; then
  log "ERROR: TEXTBELT_KEY not set."
  exit 1
fi

WAN_IFACE="$(find_wan_iface 2>/dev/null || true)"
WAN_IP=""
if [ -n "$WAN_IFACE" ]; then
  WAN_IP="$(ip -4 addr show dev "$WAN_IFACE" 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)"
fi

MSG="GL.iNet router booted after power outage.
Time: $(date '+%F %T %Z')"
[ -n "$WAN_IFACE" ] && MSG="$MSG
WAN IF: $WAN_IFACE"
[ -n "$WAN_IP" ] && MSG="$MSG
WAN IP: $WAN_IP"

log "Sending via Textbelt to $PHONE"

RESP="$(curl -sS -X POST https://textbelt.com/text \
  --data-urlencode phone="$PHONE" \
  --data-urlencode message="$MSG" \
  -d key="$TEXTBELT_KEY" 2>>"$LOG" || true)"

echo "[$(date '+%F %T')] Textbelt response: $RESP" >> "$LOG"

echo "$RESP" | grep -q '"success":[[:space:]]*true'
if [ $? -eq 0 ]; then
  log "Textbelt SMS sent."
  echo "$now" > "$STATE"
  exit 0
fi

log "Textbelt SMS failed."
exit 1
