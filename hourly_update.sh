#!/bin/sh

# ================= CONFIGURATION =================
# ⚠️ REPLACE WITH YOUR NEW TOKEN
TOKEN="YOUR_NEW_BOT_TOKEN_HERE"
CHAT_ID="457218247"
LOG="/var/log/router-hourly.log"
LOCK_FILE="/var/run/router_bot.lock"  # Prevents multiple instances

POLL_INTERVAL=10
REPORT_INTERVAL=3600
WAITING_FOR_RUN_CMD=0
# =================================================

# --- 🔒 SINGLETON CHECK (PREVENTS DUPLICATES) ---
if [ -f "$LOCK_FILE" ]; then
  # Check if the process ID in the lock file is actually running
  PID=$(cat "$LOCK_FILE")
  if ps | grep "^[[:space:]]*$PID " >/dev/null; then
    echo "❌ Script is already running (PID: $PID). Exiting."
    exit 1
  fi
fi

# Create new lock
echo $$ > "$LOCK_FILE"

# Ensure lock is removed when script exits (even if crashed)
trap 'rm -f "$LOCK_FILE"; exit' INT TERM EXIT

# =================================================

LAST_UPDATE_ID=0

send_msg() {
  /usr/bin/curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" --data-urlencode "text=$1" >/dev/null 2>&1
}

get_time_12h() { date '+%I:%M %p'; }

get_last_reboot_time() {
  UP_SEC=$(cut -d. -f1 /proc/uptime)
  NOW_SEC=$(date +%s)
  BOOT_SEC=$((NOW_SEC - UP_SEC))
  date -d @"$BOOT_SEC" "+%I:%M %p (%d-%b)" 2>/dev/null || echo "Unknown"
}

human_uptime() {
  UTS=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
  days=$((UTS / 86400))
  hours=$(((UTS % 86400) / 3600))
  mins=$(((UTS % 3600) / 60))
  printf "%dd %dh %dm" "$days" "$hours" "$mins"
}

get_public_ip() {
  curl -s --max-time 3 https://api.ipify.org || echo "Offline"
}

generate_welcome() {
  HOSTNAME=$(cat /proc/sys/kernel/hostname)
  LAST_REBOOT=$(get_last_reboot_time)
  UP=$(human_uptime)
  PUB_IP=$(get_public_ip)

  awk '/MemAvailable:/ {free=$2} /MemTotal:/ {total=$2} END {
     used=total-free
     p_free=int((free*100)/total)
     p_used=100-p_free
     f_mb=int(free/1024)
     u_mb=int(used/1024)
     print "RAM_USED=" u_mb " RAM_FREE=" f_mb " PCT_USED=" p_used " PCT_FREE=" p_free
  }' /proc/meminfo > /tmp/ram_calc
  . /tmp/ram_calc

  awk '/SwapTotal:/ {total=$2} /SwapFree:/ {free=$2} END {
     if(total>0){
       used=total-free
       f_mb=int(free/1024)
       u_mb=int(used/1024)
       print "SWAP_USED=" u_mb " SWAP_FREE=" f_mb
     } else {
       print "SWAP_USED=0 SWAP_FREE=0"
     }
  }' /proc/meminfo > /tmp/swap_calc
  . /tmp/swap_calc
  
  OVERLAY=$(df -h /overlay 2>/dev/null | awk 'NR==2{print $2}')

  MSG="🚀 *Router is Online*
---------------------------
🏷 *HOST:* ${HOSTNAME}
🕒 *Last Logged:* ${LAST_REBOOT}
⏱ *UPTIME:* ${UP}
🌍 *Public IP:* ${PUB_IP}
---------------------------
💾 *RAM:* ${RAM_USED}MB Occupied / ${RAM_FREE}MB Free (${PCT_USED}% Used)
⇄ *SWAP:* ${SWAP_USED}MB Occupied / ${SWAP_FREE}MB Free
📂 *Storage:* ${OVERLAY}"

  echo "$MSG"
}

generate_health() {
  UP=$(human_uptime)
  
  awk '/MemAvailable:/ {free=$2} /MemTotal:/ {total=$2} END {
    u=int((total-free)/1024); t=int(total/1024); p=int((free*100)/total)
    print "RAM_STR=\"" u "MB / " t "MB (" p "% free)\""
  }' /proc/meminfo > /tmp/ram_simple
  . /tmp/ram_simple

  TOP_LIST=$(top -b -n1 | head -n 10 | tail -n 5 | awk '{print $1 " -> " $NF " -> " $3 " -> " $5}')

  MSG="🏥 *Health Report*
--------------------
⏱ *Uptime:* ${UP}
💾 *RAM:* ${RAM_STR}
--------------------
⚙️ *TOP 5 Processes:*
(PID -> Name -> User -> Mem)
\`${TOP_LIST}\`"
  
  echo "$MSG"
}

generate_status() {
  if ping -q -c 1 -W 2 8.8.8.8 >/dev/null; then NET="✅ Working"; else NET="❌ Offline"; fi
  WAN=$(get_public_ip)
  CLIENTS=$(grep -v "IP address" /proc/net/arp | wc -l)
  
  MSG="📶 *Network Status*
--------------------
🌐 *Internet:* ${NET}
🌍 *WAN IP:* ${WAN}
👥 *Total Clients:* ${CLIENTS}
(Subnet: 192.168.0.1/24)"

  echo "$MSG"
}

generate_help() {
  MSG="📖 *Bot Command List*

🔹 *TP STATUS* - Network Check
🔹 *TP HEALTH* - System Resources
🔹 *TP RUN* - Execute Commands
🔹 *TP REBOOT* - Restart Router
🔹 *TP HELP* - Show this menu"
   
   echo "$MSG"
}

flush_updates() {
  RESP=$(curl -s -m 10 "https://api.telegram.org/bot${TOKEN}/getUpdates")
  LATEST_ID=$(echo "$RESP" | sed -n 's/.*"update_id":\([0-9]*\).*/\1/p' | tail -n1)
  if [ -n "$LATEST_ID" ]; then
    LAST_UPDATE_ID="$LATEST_ID"
    NEXT_ID=$((LATEST_ID + 1))
    curl -s -m 5 "https://api.telegram.org/bot${TOKEN}/getUpdates?offset=${NEXT_ID}" >/dev/null
  fi
}

check_updates() {
  OFFSET_PARAM=""
  if [ "$LAST_UPDATE_ID" -ne 0 ]; then
    NEXT_ID=$((LAST_UPDATE_ID + 1))
    OFFSET_PARAM="?offset=${NEXT_ID}"
  fi
  
  RESP=$(curl -s -m 10 "https://api.telegram.org/bot${TOKEN}/getUpdates${OFFSET_PARAM}")
  NEW_ID=$(echo "$RESP" | sed -n 's/.*"update_id":\([0-9]*\).*/\1/p' | tail -n1)
  RAW_TEXT=$(echo "$RESP" | sed -n 's/.*"text":"\([^"]*\)".*/\1/p' | tail -n1)
  
  if [ -n "$NEW_ID" ] && [ "$NEW_ID" != "$LAST_UPDATE_ID" ]; then
    LAST_UPDATE_ID="$NEW_ID"
    
    if [ "$WAITING_FOR_RUN_CMD" -eq 1 ]; then
        SAFE_CMD=$(echo "$RAW_TEXT" | tr -d ';|&`$')
        if echo "$SAFE_CMD" | grep -Eq "rm|dd|mv|mkfs|reboot|poweroff|wget|curl"; then
           send_msg "⚠️ *Security Alert:* Dangerous command blocked."
        else
           send_msg "💻 Executing: \`$SAFE_CMD\`..."
           OUTPUT=$($SAFE_CMD 2>&1 | head -c 1500)
           if [ -z "$OUTPUT" ]; then OUTPUT="(No Output)"; fi
           send_msg "\`\`\`
$OUTPUT
\`\`\`"
        fi
        WAITING_FOR_RUN_CMD=0
        return
    fi

    if echo "$RAW_TEXT" | grep -iq "^TP HEALTH$"; then
        send_msg "🏥 Generating Health Report..."
        REPORT=$(generate_health)
        send_msg "$REPORT"

    elif echo "$RAW_TEXT" | grep -iq "^TP STATUS$"; then
        send_msg "📶 Checking Network..."
        REPORT=$(generate_status)
        send_msg "$REPORT"
        
    elif echo "$RAW_TEXT" | grep -iq "^TP HELP$"; then
        REPORT=$(generate_help)
        send_msg "$REPORT"

    elif echo "$RAW_TEXT" | grep -iq "^TP RUN$"; then
        WAITING_FOR_RUN_CMD=1
        send_msg "⚠️ *Command Mode Active*"

    elif echo "$RAW_TEXT" | grep -iq "^TP REBOOT$"; then
         send_msg "⚠️ *Reboot Initiated* (Bye!)"
         sleep 2
         reboot
    fi
  fi
}

mkdir -p "$(dirname "$LOG")" 2>/dev/null
touch "$LOG"

flush_updates
WELCOME=$(generate_welcome)
send_msg "$WELCOME"

SECONDS_COUNTER=0

while true; do
  check_updates
  if [ "$SECONDS_COUNTER" -ge "$REPORT_INTERVAL" ]; then
    send_msg "🕒 *Hourly Update*"
    REPORT=$(generate_health)
    send_msg "$REPORT"
    SECONDS_COUNTER=0
  fi
  sleep "$POLL_INTERVAL"
  SECONDS_COUNTER=$((SECONDS_COUNTER + POLL_INTERVAL))
done