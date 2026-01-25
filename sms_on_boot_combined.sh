#!/bin/sh
LOG="/tmp/sms_on_boot_combined.log"
STATE="/etc/sms_on_boot_combined.last"
COOLDOWN=300

# Defaults (can be overridden by /etc/sms_on_boot_combined.conf)
PHONE="+11234567890"
PREFER="textbelt"
TEXTBELT_KEY=""
WEBHOOK_URL=""
WEBHOOK_CONNECT_TIMEOUT=5
WEBHOOK_TIMEOUT=15

CONF="/etc/sms_on_boot_combined.conf"
if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  . "$CONF"
fi

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }
log "Script start"

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

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

send_textbelt() {
  if [ -z "$TEXTBELT_KEY" ]; then
    log "Textbelt: key not set"
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    log "Textbelt: curl not found"
    return 1
  fi

  RESP="$(curl -sS --connect-timeout 5 --max-time 15 -X POST https://textbelt.com/text \
    --data-urlencode phone="$PHONE" \
    --data-urlencode message="$MSG" \
    -d key="$TEXTBELT_KEY" 2>>"$LOG" || true)"

  echo "[$(date '+%F %T')] Textbelt response: $RESP" >> "$LOG"
  echo "$RESP" | grep -q '"success":[[:space:]]*true'
}

send_sendsms() {
  if ! command -v sendsms >/dev/null 2>&1; then
    log "sendsms: sendsms not found"
    return 1
  fi
  sendsms "$PHONE" "$MSG" international >/dev/null 2>&1
}

# Cooldown guard
now="$(date +%s)"
if [ -f "$STATE" ]; then
  last="$(cat "$STATE" 2>/dev/null | tr -dc '0-9')"
  if [ -n "$last" ] && [ $((now-last)) -lt "$COOLDOWN" ]; then
    log "Cooldown active, skipping"
    exit 0
  fi
fi

# Only wait for SMS daemons if sendsms exists
if command -v sendsms >/dev/null 2>&1; then
  i=0
  while [ $i -lt 60 ]; do
    pidof sms_manager >/dev/null 2>&1 && pidof smsd >/dev/null 2>&1 && break
    sleep 2
    i=$((i+1))
  done
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

send_webhook() {
  [ -z "$WEBHOOK_URL" ] && return 0
  if ! command -v curl >/dev/null 2>&1; then
    log "Webhook: curl not found"
    return 1
  fi

  payload="$(printf '{"event":"boot","time":"%s","wan_iface":"%s","wan_ip":"%s","message":"%s"}' \
    "$(date '+%F %T %Z')" \
    "$(json_escape "${WAN_IFACE:-}")" \
    "$(json_escape "${WAN_IP:-}")" \
    "$(json_escape "$MSG")")"

  resp="$(curl -sS --connect-timeout "$WEBHOOK_CONNECT_TIMEOUT" --max-time "$WEBHOOK_TIMEOUT" \
    -H "Content-Type: application/json" -d "$payload" -w '\n%{http_code}' \
    "$WEBHOOK_URL" 2>>"$LOG" || true)"

  body="$(printf '%s' "$resp" | sed '$d')"
  code="$(printf '%s' "$resp" | tail -n 1)"

  [ -n "$body" ] && log "Webhook response body: $body"
  [ -n "$code" ] && log "Webhook response code: $code"

  case "$code" in
    2*|3*) return 0 ;;
  esac
  return 1
}

if send_webhook; then
  log "Webhook sent."
else
  log "Webhook failed."
fi

# If no WAN IP, skip Textbelt
if [ -z "$WAN_IP" ]; then
  log "No WAN IP detected; skipping Textbelt"
  TEXTBELT_KEY=""
fi

log "Preferred provider: $PREFER"

if [ "$PREFER" = "textbelt" ]; then
  if send_textbelt; then
    log "Sent via Textbelt"
    echo "$now" > "$STATE"
    exit 0
  fi
  if send_sendsms; then
    log "Sent via sendsms"
    echo "$now" > "$STATE"
    exit 0
  fi
else
  if send_sendsms; then
    log "Sent via sendsms"
    echo "$now" > "$STATE"
    exit 0
  fi
  if send_textbelt; then
    log "Sent via Textbelt"
    echo "$now" > "$STATE"
    exit 0
  fi
fi

log "All providers failed"
exit 1
