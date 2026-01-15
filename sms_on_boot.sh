#!/bin/sh
LOG="/tmp/sms_on_boot.log"
STATE="/etc/sms_on_boot.last"
COOLDOWN=300   # seconds (5 min)

PHONE="+13038675309"   # <-- change if needed

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

# Try to find the active WAN interface (cellular/wan) in a model-agnostic way.
# Priority:
#  1) default route device (common + accurate)
#  2) known cellular interface name patterns with an IPv4 address
find_active_wan_iface() {
  # 1) Default route dev
  dev="$(ip route 2>/dev/null | awk '/^default /{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
  if [ -n "$dev" ]; then
    case "$dev" in
      lo|br-lan|lan*|eth*|en*|wl*|wlan*|phy*|ap*|bat*|ifb*|docker*|veth*|tun*|wg*|tailscale* ) ;;
      * )
        ip -4 addr show dev "$dev" 2>/dev/null | grep -q "inet " && { echo "$dev"; return 0; }
        ;;
    esac
  fi

  # 2) Pattern scan: cellular interfaces often match these
  for dev in $(ls /sys/class/net 2>/dev/null); do
    case "$dev" in
      rmnet*|wwan*|usb*|cdc*|mhi*|ccmni* )
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

# Wait up to 2 minutes for SMS services + modem to be up
i=0
while [ $i -lt 60 ]; do
  pidof sms_manager >/dev/null 2>&1 && pidof smsd >/dev/null 2>&1 && break
  sleep 2
  i=$((i+1))
done

WAN_IFACE="$(find_active_wan_iface || true)"
WAN_IP=""
if [ -n "$WAN_IFACE" ]; then
  WAN_IP="$(ip -4 addr show dev "$WAN_IFACE" 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1)"
fi

MSG="GL.iNet router booted after power outage.
Time: $(date '+%F %T %Z')"
[ -n "$WAN_IFACE" ] && MSG="$MSG
WAN IF: $WAN_IFACE"
[ -n "$WAN_IP" ] && MSG="$MSG
Cell IP: $WAN_IP"

log "Sending SMS to $PHONE"
if sendsms "$PHONE" "$MSG" international; then
  log "SMS sent."
  echo "$now" > "$STATE"
  exit 0
else
  log "SMS failed."
  exit 1
fi
